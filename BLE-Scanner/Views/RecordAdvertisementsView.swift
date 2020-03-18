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

    var timeRecordedString: String {
        return String(format: "%.2f s", Float(self.timePassed))
    }
    
    @State var exportURL: URL?
    @State var showExportSheet = false

    
    var body: some View {
        ZStack {
            VStack {
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
                }
                .padding()
                
                
                Spacer()
                
                Button(self.isRecording ? "Stop Recording" : "Start Recording") {
                    //                withAnimation {self.isRecording.toggle()}
                    self.isRecording.toggle()
                    if self.isRecording {
                        self.recording = RecordingModel()
                    }else {
                        self.exportToJson()
                    }
                    self.bleScanner.scanning = self.isRecording
                }
                .sheet(isPresented: $showExportSheet) {
                    ActivityViewController(activityItems: [self.exportURL!])
                }
                Spacer()
                
            }
            
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
            var rssis = self.recording?.rssiDevices[event.device.id] ?? []
            if let lastrssi = event.advertisement.rssi.last?.floatValue {
                rssis.append(lastrssi)
            }
            
            self.recording?.rssiDevices[event.device.id] = rssis
        }
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
    
    var jsonExport: Data? {
        try? JSONSerialization.data(withJSONObject: self.rssiDevices)
    }
}
