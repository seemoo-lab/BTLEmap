//
//  EnvironmentScanner.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 03.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI

class EnvironmentViewModel: ObservableObject {
    var angles = [BLEDevice : CGFloat]()
    var lastAngle: CGFloat = 0
    
    @Published var maxRSSI: Int = 1
    
    func updateViewModel(for devices: [BLEDevice]) {
        var angle: CGFloat = 0
        let angleStep = 2 * CGFloat.pi / CGFloat(devices.count)
        
        maxRSSI = 1
        
        devices.forEach { (d) in
            angles[d] = angle
            angle += angleStep
            
            if maxRSSI < abs(d.lastRSSI.intValue) {
                maxRSSI = abs(d.lastRSSI.intValue)
            }
        }
    }
}

struct EnvironmentScanner: View {
    @EnvironmentObject var bleScanner: BLEScanner_SwiftUI
    
    var viewModel = EnvironmentViewModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BackgroundView(viewModel: self.viewModel)
                
                //Draw devices
                GeometryReader { geometry  in
                    ZStack {
                        ForEach(self.bleScanner.devices) { device in
                            DeviceOnCircleView(device: device)
                                .position(self.position(for: device.lastRSSI, size: geometry.size, angle: self.angle(for: device)))
                        }
                    }
                    .animation(.linear)
                }
            }
            .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.9, alignment: .center)
        }
        .onReceive(self.bleScanner.objectWillChange) { (bleScanner) in
            self.viewModel.updateViewModel(for: self.bleScanner.devices)
        }
    }
    
    func angle(for device: BLEDevice) -> CGFloat{
        if self.viewModel.angles[device] == nil {
            self.viewModel.updateViewModel(for: self.bleScanner.devices)
        }
        
        return self.viewModel.angles[device]!
    }
    
    func position(for rssi: NSNumber, size: CGSize, angle: CGFloat) -> CGPoint {
        let circleSize: CGFloat = {
            if size.width > size.height {
                return size.height
            }
            return size.width
        }()
        
        let rssiMax = CGFloat(self.viewModel.maxRSSI)
        let distance: CGFloat = {
            if CGFloat(rssi.floatValue) < -rssiMax {
                return circleSize/2
            }
            
            return circleSize/2 * CGFloat(abs(rssi.floatValue))/rssiMax
        }()
       
        let distX = distance * cos(angle)
        let distY = distance * sin(angle)
        
        
        return CGPoint(x: size.width/2 - distX, y: size.height/2 - distY)
    }
}



struct EnvironmentScanner_Previews: PreviewProvider {
    static var previews: some View {
        EnvironmentScanner()
    }
}

struct BackgroundView: View {
    let strokeStyle = StrokeStyle(lineWidth: 2.0)
    let circleColor = Color.gray
    @ObservedObject var viewModel: EnvironmentViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                
                Circle()
                    .fill(self.circleColor)
                    .frame(width: geometry.size.width * 0.1, height: geometry.size.height * 0.1, alignment: .center)
                Text("\(String(format: "-%.2f", Float(self.viewModel.maxRSSI) * 0.1)) dBm")
                    .position(x: geometry.size.width/2, y: geometry.size.height * 0.05 + geometry.size.height/2 + 10.0)
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width/4, height: geometry.size.height/4, alignment: .center)
                Text("\(String(format: "-%.2f", Float(self.viewModel.maxRSSI) * 0.25)) dBm")
                    .position(x: geometry.size.width/2, y: geometry.size.height * 0.125 + geometry.size.height/2 + 10.0)
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width/2, height: geometry.size.height/2, alignment: .center)
                
                Text("\(String(format: "-%.2f", Float(self.viewModel.maxRSSI) * 0.5)) dBm")
                    .position(x: geometry.size.width/2, y: geometry.size.height * 0.25 + geometry.size.height/2 + 10.0)
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width * 0.75, height: geometry.size.height * 0.75, alignment: .center)
                
                Text("\(String(format: "-%.2f", Float(self.viewModel.maxRSSI) * 0.75)) dBm")
                    .position(x: geometry.size.width/2, y: geometry.size.height * 0.375 + geometry.size.height/2 + 10.0)
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                
                Text("\(String(format: "-%.2f", Float(self.viewModel.maxRSSI) )) dBm")
                    .position(x: geometry.size.width/2, y: geometry.size.height * 0.5 + geometry.size.height/2 + 10.0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }
}

struct DeviceOnCircleView: View {
    @State var device: BLEDevice
    var angle = (CGFloat(arc4random()) / CGFloat(RAND_MAX)) * CGFloat(2) * CGFloat.pi
    
    var deviceName: String {
        switch self.device.deviceType {
        case .AirPods:
            return "AirPods"
        case .appleEmbedded:
            return "Embedded"
        case .iMac:
            return "iMac"
        case .AppleWatch:
            return "Apple Watch"
        case .iPad: return "iPad"
        case .iPod: return "iPod"
        case .iPhone: return "iPhone"
        case .macBook: return "MacBook"
        case .other: return "Other"
        case .Pencil: return "Pencil"
        case .none: return "Other"
        }
    }
    
    var body: some View {
        VStack {
            Image(self.deviceName)
                .resizable()
                .background(
                    RoundedRectangle(cornerRadius: 5.0)
                        .fill(Color.white)
                )
                .aspectRatio(contentMode: .fit)
                .frame(height: 45.0)
                
                
            
            Text(self.deviceName)
                .frame(width: 100)
                .background(Color.white)
                
            
            Text("RSSI: \(device.lastRSSI.intValue) dBm")
                .frame(width: 100.0)
                .font(.footnote)
                .background(Color.white)
        }
        
    }
    
    
}
