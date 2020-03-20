//
//  RecordAdvertisementsView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 17.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import BLETools
import CoreMotion


struct RecordAdvertisementsView: View {
    @EnvironmentObject var bleScanner: BLEScanner
    @Binding var isShown: Bool
    
    @State var isRecording: Bool = false
    @State var showError = false
    @State var recording: RecordingModel?
    @State var timePassed: Double = 0.0
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    
    @State var selectedManufacturers: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}
    @State var showManufacturerSelection = false

    var timeRecordedString: String {
        return String(format: "%.2f s", Float(self.timePassed))
    }
    
    @State var exportURLs: [URL]?
    @State var showExportSheet = false
    
    static let motion = CMMotionManager()
    
    var plots: some View {
        self.recording.map({ recording in
            GeometryReader { geometry in
                ScrollView {
                    RSSIPlots(recording: recording, width: geometry.size.width)
                }
                .transition(AnyTransition.opacity.animation(.easeIn))
            }
        })
    }
    
    
    var exportButton: some View {
        Button(action: {
            self.exportRecording()
        }, label: {
            Image(systemName: "square.and.arrow.up")
                .imageScale(.large)
                .padding()
        })
    }
    
    var recordingTimeView: some View {
        HStack(alignment: .center) {
            Text("Time recording")
            Text(self.timeRecordedString)
                .font(.system(.body, design: .monospaced))
                .onReceive(timer) { (_) in
                    guard self.isRecording else {return}
                    if let recording = self.recording {
                        self.timePassed = abs(recording.startDate.timeIntervalSinceNow)
                    }
            }
            
            Spacer()
            
            self.filterButton
                .transition(AnyTransition.slide.animation(.easeIn))
            
            if self.recording != nil && !self.isRecording {
                self.exportButton
                    .transition(AnyTransition.slide.animation(.easeIn))
            }
        }
        .padding()

    }
    
    var filterButton: some View {
        Button(action: {
            self.showManufacturerSelection.toggle()
        }, label:  {
            Image(systemName: "line.horizontal.3.decrease.circle")
                .imageScale(.large)
                .padding()
        })
        .popoverSheet(isPresented: self.$showManufacturerSelection, content: {
            ManfucaturerSelection(selectedManufacturers: self.$selectedManufacturers, isShown: self.$showManufacturerSelection)
        })
    }
    
    
    var recordingButton: some View {
        Group {
            Button(self.isRecording ? "Stop Recording" : "Start Recording") {
                self.toggleRecording()
            }
            .padding()
            .sheet(isPresented: $showExportSheet) {
                ActivityViewController(activityItems: self.exportURLs!, completionWithItemsHandler: { (activityType, completed, items, error) in
                    self.showExportSheet = false
                })
            }
            
            if isRecording {
                Button("Looking at Device") {
                     if let yaw = RecordAdvertisementsView.motion.deviceMotion?.attitude.yaw {
                        self.recording?.manualAngles.append(yaw)
                     }
                }
                .padding()
            }
        }
    }
    
    var recordingInfoView: some View {
        VStack {
            if self.isRecording {
                Spacer()
                VStack {
                    Text("Detected \(self.recording!.rssiDevices.keys.count) devices")
                    .padding()
                        .foregroundColor(Color.white)
                }
                .background(
                    RoundedRectangle(cornerRadius: 7.5, style: .continuous)
                        .fill(Color.gray))
                    .transition(AnyTransition.opacity.animation(.linear(duration: 0.3)))
                    .frame(alignment: .bottom)
            }
        }

    }
    
    var body: some View {
        ZStack {
            VStack {
                
                HStack {
                    Spacer()
                    Button("Btn_Dismiss") {self.isShown = false}.padding([.top,.trailing])
                }
                
                Divider()
                
                self.recordingTimeView
                
                Spacer()
                
                self.recordingButton
                
                Spacer()
                
                if !self.isRecording  {
                    self.plots
                        .padding()
                }
                
                
            }
            
            self.recordingInfoView
                .padding(.bottom)

        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .alert(isPresented: self.$showError, content: { () -> Alert in
            Alert(title: Text("Export failed"), message: Text("Failed exporting results. Please try again"), dismissButton: .cancel())
        })
        .onAppear(perform: {
            self.bleScanner.filterDuplicates = false
            self.bleScanner.scanning = self.isRecording
        })
        .onDisappear(perform: {
            self.bleScanner.filterDuplicates = true
        })
        .onReceive(self.bleScanner.newAdvertisementSubject) { (event) in
            guard self.isRecording else {return}
            self.received(ble: event)
        }
    }
    
    func received(ble event: BLEScanner.BLE_Event) {
        
        guard self.selectedManufacturers.contains(event.device.manufacturer.rawValue.capitalized) else {return}
        
        var rssis = self.recording?.rssiDevices[event.device.id] ?? []
        var data = self.recording?.recordedData[event.device ] ?? [RecordingModel.RecordingEntry]()
        
        if let lastrssi = event.advertisement.rssi.last?.floatValue {
            rssis.append(lastrssi)
            
            if let yaw = RecordAdvertisementsView.motion.deviceMotion?.attitude.yaw {
                data.append(RecordingModel.RecordingEntry(yaw: yaw, rssi: lastrssi, time: -(recording?.startDate.timeIntervalSinceNow ?? 0.0) ))
            }
            
        }
        self.recording?.rssiDevices[event.device.id] = rssis
        self.recording?.recordedData[event.device] = data
    }
    
    func toggleRecording() {
        
        self.isRecording.toggle()
        if self.isRecording {
            self.recording = RecordingModel()
            //Start Core Motion
            self.startCoreMotionReceiving()
        }else {
            RecordAdvertisementsView.motion.stopDeviceMotionUpdates()
        }
        self.bleScanner.scanning = self.isRecording
    }
    
    func startCoreMotionReceiving() {
        guard RecordAdvertisementsView.motion.isDeviceMotionAvailable else {return}
        
        RecordAdvertisementsView.motion.deviceMotionUpdateInterval = 1.0/5.0
        RecordAdvertisementsView.motion.showsDeviceMovementDisplay = true
        RecordAdvertisementsView.motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
    }
    

    func exportRecording() {
        guard let recording = self.recording else {
            self.showError = true
            return
        }
        
        var exportURLs = recording.csvExport
        if let pdfURL = self.createPlotPDF() {
            exportURLs.append(pdfURL)
        }
        
        self.exportURLs = exportURLs
        self.showExportSheet = true
        
    }
    
    
    func createPlotPDF() -> URL? {
        guard let recording = self.recording else {
            self.showError = true
            return nil
        }
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputFileURL = documentDirectory.appendingPathComponent("Charts.pdf")
        
        let width: CGFloat = 8.5 * 72.0
        let height: CGFloat = CGFloat(recording.rssiDevices.keys.count) * CGFloat(280)
        let plots = RSSIPlots(recording: recording, width: width)
        
        let pdfVC = UIHostingController(rootView: plots)
        pdfVC.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        
        let rootVC = UIApplication.shared.windows.first?.rootViewController
        rootVC?.addChild(pdfVC)
        rootVC?.view.insertSubview(pdfVC.view, at: 0)
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 8.5 * 72.0, height: height))
        
        do {
            try pdfRenderer.writePDF(to: outputFileURL, withActions: { (context) in
                context.beginPage()
                pdfVC.view.layer.render(in: context.cgContext)
            })
            
            pdfVC.removeFromParent()
            pdfVC.view.removeFromSuperview()
           
        }catch {
            self.showError = true
            print("Could not create PDF file: \(error)")
            
            pdfVC.removeFromParent()
            pdfVC.view.removeFromSuperview()
            return nil
        }
        
        return outputFileURL
    }
    
}

struct RecordAdvertisementsView_Previews: PreviewProvider {
    @State static var isShown = false
    
    static var previews: some View {
        RecordAdvertisementsView(isShown: $isShown)
    }
}

struct RecordingModel {
    var startDate: Date = Date()
    var endDate: Date?
    /// All RSSIs received for one device
    var rssiDevices = [String: [Float]]()
//    var advertisements = [BLEAdvertisment]()
    
    var recordedData = [BLEDevice: [RecordingEntry]]()
    
    var drawableRSSIs: [(key: String, value: [Float])] {
        rssiDevices.map{($0.key, $0.value)}.sorted(by: {$0.key < $1.key})
    }
    
    var jsonExport: Data? {
        try? JSONSerialization.data(withJSONObject: self.rssiDevices)
    }
    
    var manualAngles: [Double] = []
    
    var csvExport: [URL] {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let csvDirFileURL = documentDirectory.appendingPathComponent("/csvs")
        try? FileManager.default.createDirectory(at: csvDirFileURL, withIntermediateDirectories: false, attributes: nil)
        
        return recordedData.compactMap {
            var csv = "Time;Angle;RSSI\n"
            let entryStrings = $0.value.map({
                "\(String(format:"%0.2f", $0.time)); \(String(format:"%0.5f", $0.yaw)); \(String(format:"%0.2f", $0.rssi))"
                }).joined(separator: "\n")
            csv += entryStrings
            
            let csvURL = csvDirFileURL.appendingPathComponent($0.key.id + ".csv")
            do {
                try csv.write(to: csvURL, atomically: true, encoding: .utf8)
                return csvURL
            }catch {
                print("Failed to write CSV \(error)")
            }
            
            return nil
        }
    }
    
    struct RecordingEntry {
        /// Rotation of the device on the Z-axis in radians
        let yaw: Double
        /// RSSI value received at this point
        let rssi: Float
        
        let time: TimeInterval
    }
}


