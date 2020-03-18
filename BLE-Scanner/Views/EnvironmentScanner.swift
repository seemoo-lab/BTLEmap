//
//  EnvironmentScanner.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 03.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import BLETools

class EnvironmentViewModel: ObservableObject {
    var angles = [BLEDevice : CGFloat]()
    var lastAngle: CGFloat = 0
    var detailDevice: BLEDevice?
    
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
    @EnvironmentObject var bleScanner: BLEScanner
    @EnvironmentObject var viewModel: EnvironmentViewModel
    @Environment(\.horizontalSizeClass) var sizeClass
    
    @State var showDetail: Bool = false
    
    @State var selectedManufacturers: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}
    @State var minimumRSSI: Float = -.infinity
    
    static var sheetTransition: AnyTransition {
        let insertion = AnyTransition.move(edge: .bottom)
            .combined(with: .opacity)
        let removal = AnyTransition.move(edge: .bottom)
            .combined(with: .opacity)
        
        return .asymmetric(insertion: insertion, removal: removal)
    }
    

    var presentedDevices: [BLEDevice] {
        var devices = self.bleScanner.deviceList
        
        //Filter out all unselected devices
        devices = devices.filter {self.selectedManufacturers.contains($0.manufacturer.rawValue.capitalized)}
        
        devices = devices.filter {$0.lastRSSI.floatValue > self.minimumRSSI}
        
        return devices
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                
                HStack {
                    FilterSettings(selectedManufacturers: self.$selectedManufacturers, minimumRSSI: self.$minimumRSSI)
                    .padding()
                }
                
                Spacer(minLength: 20.0)
                
                //Scanner view
                ZStack {
                    GeometryReader { geometry  in
                        ZStack {
                            BackgroundView(viewModel: self.viewModel)
                            
                            //Draw devices
                            
                            ForEach(self.presentedDevices) { device in
                                Button(action: {
                                    self.viewModel.detailDevice = device
                                    self.showDetail = true
                                }, label: {
                                    DeviceOnCircleView(device: device)
                                })
                                .buttonStyle(PlainButtonStyle())
                                .position(self.position(for: device.lastRSSI, size: geometry.size, angle: self.angle(for: device)))
                                .sheet(isPresented: self.$showDetail) {
                                    DeviceDetailView(device: self.viewModel.detailDevice!, showInModal: true, isShown: self.$showDetail)
                                }
                                
                            }
                        }
                        .animation(.linear)
                    }
                }
                .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.8, alignment: .center)
                
                Spacer()
            }
        }
        .onReceive(self.bleScanner.objectWillChange) { (bleScanner) in
            self.viewModel.updateViewModel(for: self.bleScanner.deviceList)
        }
        
        
    }
    
    func angle(for device: BLEDevice) -> CGFloat{
        if self.viewModel.angles[device] == nil {
            self.viewModel.updateViewModel(for: self.bleScanner.deviceList)
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
    
    struct FilterSettings:View {
        @Binding var selectedManufacturers: [String]
        @Binding var minimumRSSI:Float
        @State var showManufacturerSelection = false
        @EnvironmentObject var bleScanner: BLEScanner
        @State var devicesCanTimeout = true
        
        var timeoutButton: some View {
            
            Button(action: {
                self.bleScanner.devicesCanTimeout.toggle()
                self.devicesCanTimeout = self.bleScanner.devicesCanTimeout
            }) {
                if self.devicesCanTimeout {
                    HStack{Image(systemName:"checkmark.circle"); Text("Timeout devices")}
                }else {
                    HStack{Image(systemName:"circle"); Text("Timeout devices")}
                }
            }
            .buttonStyle(PlainButtonStyle())
            
        }
        
        var filterButton: some View {
            Button(action: {
                self.showManufacturerSelection.toggle()
            }, label:  {
                Text("Btn_filter_manufacturers")
                    .padding(10)
            })
                .popoverSheet(isPresented: self.$showManufacturerSelection, content: {
                    ManfucaturerSelection(selectedManufacturers: self.$selectedManufacturers, isShown: self.$showManufacturerSelection)
                })
        }
        
        var sliderRange = Float(-100.0)...Float(0.0)
        
        
        var body: some View {
            Group {
                
                self.timeoutButton
                
                self.filterButton
                
                Slider(value: self.$minimumRSSI,in: self.sliderRange)
                    .frame(maxWidth: 200.0)
                
                if self.minimumRSSI == -Float.infinity {
                    Text(String("Minimum RSSI -∞"))
                }else {
                    Text(String(format: "Minimum RSSI %0.fdBm", Float(self.minimumRSSI)))
                }
                
//                Slider(value: self.$minimumRSSI, in: Float(-100.0)...Float(0.0))
////                    .frame(maxWidth: CGFloat(200.0))
//                if self.minimumRSSI == -Float.infinity {
//                    Text(String("Minimum RSSI -∞"))
//                }else {
//                    Text(String(format: "Minimum RSSI %.0fdBm", self.minimumRSSI))
//                }
            }
        }
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
                    .position(x: geometry.size.width/2, y: geometry.size.smaller * 0.05 + geometry.size.height/2 + 10.0)
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width/4, height: geometry.size.height/4, alignment: .center)
                Text("\(String(format: "-%.2f", Float(self.viewModel.maxRSSI) * 0.25)) dBm")
                    .position(x: geometry.size.width/2, y: geometry.size.smaller * 0.125 + geometry.size.height/2 + 10.0)
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width/2, height: geometry.size.height/2, alignment: .center)
                
                Text("\(String(format: "-%.2f", Float(self.viewModel.maxRSSI) * 0.5)) dBm")
                    .position(x: geometry.size.width/2, y:geometry.size.smaller * 0.25 + geometry.size.height/2 + 10.0)
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width * 0.75, height: geometry.size.height * 0.75, alignment: .center)
                
                Text("\(String(format: "-%.2f", Float(self.viewModel.maxRSSI) * 0.75)) dBm")
                    .position(x: geometry.size.width/2, y: geometry.size.smaller * 0.375 + geometry.size.height/2 + 10.0)
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                
                Text("\(String(format: "-%.2f", Float(self.viewModel.maxRSSI) )) dBm")
                    .position(x: geometry.size.width/2, y: geometry.size.smaller * 0.5 + geometry.size.height/2 + 10.0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }
    

    
    func circleDiameter(from geometry: GeometryProxy) -> CGFloat {
        let circleWidth = geometry.size.width > geometry.size.height ? geometry.size.height : geometry.size.width
        
        return circleWidth
    }
}

struct DeviceOnCircleView: View {
    @ObservedObject var device: BLEDevice
    @Environment(\.horizontalSizeClass) var sizeClass
    
    @State var sending: Bool = false
    
    static var background = Color("DeviceBackground")
    
    var angle = (CGFloat(arc4random()) / CGFloat(RAND_MAX)) * CGFloat(2) * CGFloat.pi
    
    var deviceTypeString: String {
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
        case .other:
            if self.device.manufacturer == .apple {
                return "Apple"
            }
            return "Other"
        case .Pencil: return "Pencil"
        case .none: return "Other"
        }
    }
    
    var scaling: CGFloat {
        if sizeClass == .compact {
            return 0.5
        }

        return 1.0
    }
    
    var iconColor: Color {
        if self.device.lastUpdate.timeIntervalSinceNow > -1.1 {
            return Color("isSendingColor")
        }else {
            return Color("notSendingColor")
        }
    }
    
    var body: some View {
        VStack {
            
            if device.name != nil {
                Text(device.name!)
                .frame(minWidth: 100, maxWidth: 150)
                    .multilineTextAlignment(.center)
            }
            if self.device.manufacturer == .apple {
                Text(self.deviceTypeString)
                    .frame(width: 100)
                    .multilineTextAlignment(.center)
                
            }else {
                Text(self.device.manufacturer.rawValue)
                    .frame(width: 100)
            }
            
            
            Image(self.deviceTypeString)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 45.0)
                .foregroundColor(self.iconColor)
                
                
            Text("RSSI: \(device.lastRSSI.intValue) dBm")
                .frame(width: 100.0)
                .font(.footnote)
//                .background(DeviceOnCircleView.background)
        }
        .background(RoundedRectangle(cornerRadius: 10.0).fill(DeviceOnCircleView.background))
        .scaleEffect(self.scaling)
        
    }
    
}

extension CGSize {
    var smaller: CGFloat {
        return width < height ? width: height
    }
    
    var larger: CGFloat {
        return width > height ? width: height
    }
}
