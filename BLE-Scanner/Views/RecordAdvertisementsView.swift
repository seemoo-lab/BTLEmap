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
    var bleScanner = BLEScanner()
    
    @State var isRecording: Bool = false
    @State var recording: RecordingModel?
    @State var timePassed: Double = 0.0
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var timeRecordedString: String {
        return String(format: "%.2f s", Float(self.timePassed))
    }
    
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
                    }
                    self.bleScanner.scanning = self.isRecording
                }
                
                Spacer()
                
            }
            
            if self.isRecording {
                VStack {
                    Text("Recorded \(self.recording!.advertisements.count) advertisements")
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
        .frame(minWidth: 0, maxWidth: .infinity)
        .onReceive(self.bleScanner.newAdvertisementSubject) { (event) in
//            self.recording?.advertisements.append(event.advertisement)
        }
//        .background(Color.red)
        
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
    var advertisements = [BLEAdvertisment]()
    
}
