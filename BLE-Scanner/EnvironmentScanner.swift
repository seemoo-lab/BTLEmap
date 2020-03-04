//
//  EnvironmentScanner.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 03.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI

struct EnvironmentScanner: View {
    @EnvironmentObject var bleScanner: BLEScanner_SwiftUI
    
    static var angles = [BLEDevice : CGFloat]()
    

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BackgroundView()
                
                //Draw devices
                GeometryReader { geometry  in
                    ZStack {
                        ForEach(self.bleScanner.devices) { device in
                            DeviceOnCircleView()
                                .position(self.position(for: device.lastRSSI, size: geometry.size, angle: self.angle(for: device)))
                        }
                    }
                }
            }
        }
        .onReceive(self.bleScanner.objectWillChange) { (bleScanner) in
            self.bleScanner.devices.forEach { (d) in
                if EnvironmentScanner.angles[d] == nil {
                    EnvironmentScanner.angles[d] = (CGFloat(arc4random()) / CGFloat(RAND_MAX)) * CGFloat(2) * CGFloat.pi
                }
            }
        }
    }
    
    func angle(for device: BLEDevice) -> CGFloat{
        if EnvironmentScanner.angles[device] == nil {
            EnvironmentScanner.angles[device] = (CGFloat(arc4random()) / CGFloat(RAND_MAX)) * CGFloat(2) * CGFloat.pi
        }
        
        return EnvironmentScanner.angles[device]!
    }
    
    func position(for rssi: NSNumber, size: CGSize, angle: CGFloat) -> CGPoint {
        let circleSize: CGFloat = {
            if size.width > size.height {
                return size.height
            }
            return size.width
        }()
        
        let rssiMax = -100
        let distance: CGFloat = {
            if rssi.intValue < rssiMax {
                return circleSize/2 * 0.75
            }
            
            return circleSize/2 * CGFloat(abs(rssi.floatValue)/100) * 0.75
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
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                
                Circle()
                    .fill(self.circleColor)
                    .frame(width: geometry.size.width * 0.1, height: geometry.size.height * 0.1, alignment: .center)
                
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width/4, height: geometry.size.height/4, alignment: .center)
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width/2, height: geometry.size.height/2, alignment: .center)
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width * 0.75, height: geometry.size.height * 0.75, alignment: .center)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }
}

struct DeviceOnCircleView: View {
    var angle = (CGFloat(arc4random()) / CGFloat(RAND_MAX)) * CGFloat(2) * CGFloat.pi
    
    var body: some View {
        VStack {
            Rectangle()
            .frame(width: 20.0, height: 20.0, alignment: .center)
            
            Text("Device type")
        }
    }
}
