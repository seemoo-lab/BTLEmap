//
//  RecordAdvertisementsView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 17.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import BLETools


struct RecordAdvertisementsView: View {
    @EnvironmentObject var bleScanner: BLEScanner
    
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
    
    @State var exportURL: URL?
    @State var showExportSheet = false
    
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
            self.exportPlotsToPDF()
        }, label: {
            Image(systemName: "square.and.arrow.up")
                .imageScale(.large)
                .padding()
        })
    }
    
    var recordingTimeView: some View {
        HStack(alignment: .top) {
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
        Button(self.isRecording ? "Stop Recording" : "Start Recording") {
            //                withAnimation {self.isRecording.toggle()}
            self.isRecording.toggle()
            if self.isRecording {
                self.recording = RecordingModel()
            }else {
                //                        self.exportToJson()
            }
            self.bleScanner.scanning = self.isRecording
        }
        .sheet(isPresented: $showExportSheet) {
            ActivityViewController(activityItems: [self.exportURL!], completionWithItemsHandler: { (activityType, completed, items, error) in
                self.showExportSheet = false
            })
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
        var rssis = self.recording?.rssiDevices[event.device.id] ?? []
        
        guard self.selectedManufacturers.contains(event.device.manufacturer.rawValue.capitalized) else {return}
        
        if let lastrssi = event.advertisement.rssi.last?.floatValue {
            rssis.append(lastrssi)
        }
        
        self.recording?.rssiDevices[event.device.id] = rssis
    }
    
    func exportToJson() {
        guard let jsonData = self.recording?.jsonExport,
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first else {
            self.showError = true
            return
        }
        
        do {
            let jsonURL = URL(fileURLWithPath: documentDirectory).appendingPathComponent("rssiRecording.json")
            
            //Write to Sandbox
            try jsonData.write(to: jsonURL)
            
            #if targetEnvironment(macCatalyst)
            export(file: jsonURL)
            #else
            self.exportURL = jsonURL
            self.showExportSheet = true
            #endif
        }catch {
            self.showError = true
        }
        
    }
    
    func exportPlotsToPDF() {
        guard let recording = self.recording else {
            self.showError = true
            return
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
            
            self.exportURL = outputFileURL
            self.showExportSheet = true
            
        }catch {
            self.showError = true
            print("Could not create PDF file: \(error)")
        }
        
        pdfVC.removeFromParent()
        pdfVC.view.removeFromSuperview()
    }
    

    
}

struct RecordAdvertisementsView_Previews: PreviewProvider {
    static var previews: some View {
        RecordAdvertisementsView()
    }
}

struct RecordingModel {
    var startDate: Date = Date()
    var endDate: Date?
    /// All RSSIs received for one device
    var rssiDevices = [String: [Float]]()
//    var advertisements = [BLEAdvertisment]()
    
    var drawableRSSIs: [(key: String, value: [Float])] {
        rssiDevices.map{($0.key, $0.value)}.sorted(by: {$0.key < $1.key})
    }
    
    var jsonExport: Data? {
        try? JSONSerialization.data(withJSONObject: self.rssiDevices)
    }
}

struct RSSIPlots: View {
    var recording: RecordingModel
    var width: CGFloat
    
    var body: some View {
        VStack {
            Text("RSSI charts")
            ForEach(recording.drawableRSSIs, id: \.0) { rssiTuple in
                VStack {
                    Text(rssiTuple.0)
                    RSSIChart(id: rssiTuple.0, rssiValues: rssiTuple.1, width: self.width)
                        .frame(width: self.width, height: 200)
                }
                .padding([.top, .bottom])
            }
        }
    }
}

struct RSSIChart: View {
    let id: String
    let rssis: [RSSI]
    let width: CGFloat
    let height: CGFloat = 200.0
    
    init(id: String, rssiValues:[Float], width: CGFloat) {
        self.rssis = rssiValues.enumerated().map{RSSI(idx: $0.offset, value: $0.element)}
        self.id = id
        self.width = width
    }
    
    
    func lineY(lineNum line: Int) -> CGFloat {
        let dHeight = self.height / CGFloat(100)
        return self.height - dHeight * CGFloat(line * 10)
    }
    
    var body: some View {
        ZStack {
            // 1
            ForEach(0..<11) { line in
                
              // 2
              Group {
                Path { path in
                    
                    let y = self.lineY(lineNum: line)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: self.width, y: y))
                    
                  // 4
                }.stroke(line == 0 ? Color.black : Color.gray)
                // 5
                if line >= 0 {
                  Text("-\(line * 10)dBm")
                    .position(CGPoint(x: 30, y: self.lineY(lineNum: line) + CGFloat(10)))
                }
              }
            }
            
            Path { p in
                self.rssis.forEach { (rssi) in
                    // 3
                    let dWidth = self.width / CGFloat(self.rssis.count)
                    let dHeight = self.height / CGFloat(100)
                    // 4
                    let posOffset = dWidth * CGFloat(rssi.id)
                    let rssiVal = abs(rssi.value) < 100 ? abs(rssi.value) : Float(100.0)
                    let rssiOffset = dHeight * CGFloat(rssiVal)
                    
                    //                let highOffset = self.tempOffset(measurement.high, degreeHeight: dHeight)
                    // 5
                    if rssi.id == 0 {
                        p.move(to: CGPoint(x: posOffset, y: self.height - rssiOffset))
                    }else {
                        p.addLine(to: CGPoint(x: posOffset, y: self.height - rssiOffset - 10))
                    }
                    
                    
                    //                p.addLine(to: CGPoint(x: dOffset, y: reader.size.height - highOffset))
                    // 6
                }
            }
            .stroke(Color.accentColor)
        }
    }
    
//    func
    
    struct RSSI: Identifiable {
        var id: Int
        var value: Float
        
        init(idx: Int, value: Float) {
            self.id = idx
            self.value = value
        }
    }
}
