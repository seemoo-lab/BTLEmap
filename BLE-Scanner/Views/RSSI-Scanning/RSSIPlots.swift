//
//  RSSICharts.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 20.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import SwiftUI


struct RSSIPlots: View {
    var recording: RecordingModel
    var width: CGFloat
    
    var dataArray: [(device: BLEDevice, entries: [RecordingModel.RecordingEntry])] {
        recording.recordedData.map({($0.key, $0.value)})
    }
    
    
    var body: some View {
        VStack {
            Text("RSSI charts")
            ForEach(self.dataArray, id: \.0) { rssiTuple in
                VStack {
                    Text(rssiTuple.device.id)
                    RSSIChart(device: rssiTuple.device, rssiValues: rssiTuple.entries, width: self.width, plotMultipleRounds:true, manualSelections: self.recording.manualAngles)
                        .frame(width: self.width, height: 200)
                }
                .padding([.top, .bottom])
            }
        }
    }
}

struct RSSIChart: View {
    let device: BLEDevice
    let rssis: [RSSI]
    let width: CGFloat
    let height: CGFloat = 200.0
    
    var plotMultipleRounds = false
    let manualSelections: [Double]
    
    init(device: BLEDevice, rssiValues:[RecordingModel.RecordingEntry], width: CGFloat, plotMultipleRounds: Bool=false, manualSelections: [Double] = []) {
        self.rssis = rssiValues.enumerated().map{RSSI(idx: $0.offset, value: $0.element.rssi, angle: $0.element.yaw)}
        self.device = device
        self.width = width
        self.plotMultipleRounds = plotMultipleRounds
        self.manualSelections = manualSelections
    }
    
    
    func lineY(lineNum line: Int) -> CGFloat {
        let dHeight = self.height / CGFloat(100)
        return self.height - dHeight * CGFloat(line * 10)
    }
    
    func textForLine(line: Int) -> Text {
        guard !self.plotMultipleRounds else {return Text("")}
        
        if line == 0 {
            return Text("0rad")
        }
        
        if line == 5 {
            return Text("π rad")
        }
        
        if line == 10 {
            return  Text("2π rad")
        }
        
        return Text("")
    }
    
    var linesAndText: some View {
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
                
                    HStack {
                        Text("-\(line * 10)dBm")
                            
                        Spacer()
                        
                        self.textForLine(line: line)
                            
                    }
                    .position(CGPoint(x: self.width/2, y: self.lineY(lineNum: line) + CGFloat(10)))
                
              }
            }
        }
    }
    
    var anglesXLines: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: self.height))
                path.addLine(to: CGPoint(x: 0, y: 0))
            }.stroke(Color.gray)
            
            Path { path in
                path.move(to: CGPoint(x: self.width/2, y: self.height))
                path.addLine(to: CGPoint(x: self.width/2, y: 0))
            }.stroke(Color.gray)
            
            Path { path in
                path.move(to: CGPoint(x: self.width, y: self.height))
                path.addLine(to: CGPoint(x: self.width, y: 0))
            }.stroke(Color.gray)
            
            
            HStack {
                Text("0rad")
                    .offset(x: 0, y: 20.0)
                Spacer()
                Text("πrad")
                Spacer()
                Text("2πrad")
            }
            .position(CGPoint(x: self.width/2, y: self.height + 10))
            
        }
    }
    
    var rssiPath: some View {
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
                    p.addLine(to: CGPoint(x: posOffset, y: self.height - rssiOffset))
                }
                
                
                //                p.addLine(to: CGPoint(x: dOffset, y: reader.size.height - highOffset))
                // 6
            }
        }
        .stroke(Color.blue)
    }
    
    var rotationPath: some View {
        Path { p in
            self.rssis.forEach { (rssi) in
                // 3
                let dWidth = self.width / CGFloat(self.rssis.count)
                let dHeight = self.height / (2 * CGFloat.pi)
                // 4
                let posOffset = dWidth * CGFloat(rssi.id)
                let angleVal = CGFloat(rssi.angle) + CGFloat.pi
                let angleOffset = dHeight * angleVal
                
                //                let highOffset = self.tempOffset(measurement.high, degreeHeight: dHeight)
                // 5
                if rssi.id == 0 {
                    p.move(to: CGPoint(x: posOffset, y: self.height - angleOffset))
                }else {
                    p.addLine(to: CGPoint(x: posOffset, y: self.height - angleOffset))
                }
                
                
                //                p.addLine(to: CGPoint(x: dOffset, y: reader.size.height - highOffset))
                // 6
            }
        }
        .stroke(Color.orange)
    }
    
    func circlePositionFrom(rssi: RSSI) -> CGPoint {
        let dWidth: CGFloat = self.width / (2 * CGFloat.pi)
        let dHeight: CGFloat = self.height / CGFloat(100)
        
        let rssiVal = abs(rssi.value) < 100 ? abs(rssi.value) : Float(100.0)
        let yOffset = dHeight * CGFloat(rssiVal)
        let xOffset = (CGFloat(rssi.angle) + CGFloat.pi) * dWidth
        
        return CGPoint(x: xOffset, y: yOffset)
    }
    
    var angleXRSSIYPath: some View {
        
        Group {
            ForEach(self.rssis, content: { (rssi) in
                return Circle()
                    .fill(Color.orange)
                    .frame(width: 5.0, height: 5.0)
                    .position(self.circlePositionFrom(rssi: rssi))
            })
        }

    }
    
    
    var manualSelectionCircles: some View {
        ZStack {
            ForEach(self.manualSelections, id: \.self) { angle in
                Circle()
                    .fill(Color.red)
                    .frame(width: 5.0, height: 5.0)
                    .position(CGPoint(x: (CGFloat(angle) + CGFloat.pi) * (self.width / (2 * CGFloat.pi)), y: self.height - 10.0))
            }
        }
    }
    
    var body: some View {
        ZStack {
            
            if !plotMultipleRounds {
                self.linesAndText
                    .opacity(0.6)
                
                self.rssiPath
                
                self.rotationPath
            }else {
                self.linesAndText
                    .opacity(0.6)
                
                self.anglesXLines
                    .opacity(0.6)
                
                self.angleXRSSIYPath
                
                self.manualSelectionCircles
            }
        }
    }
    
    
    struct RSSI: Identifiable {
        var id: Int
        var value: Float
        var angle: Double
        
        init(idx: Int, value: Float, angle: Double) {
            self.id = idx
            self.value = value
            self.angle = angle
        }
    }
}
