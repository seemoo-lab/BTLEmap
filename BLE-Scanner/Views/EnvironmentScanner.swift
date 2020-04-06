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
    
    var maxRSSI: Int = 100
    
    func updateViewModel(for devices: [BLEDevice]) {
        var angle: CGFloat = 0
        let angleStep = 2 * CGFloat.pi / CGFloat(devices.count)
        
        maxRSSI = 1
        
        devices.forEach { (d) in
            angles[d] = angle
            angle += angleStep
        }
    }
}

struct EnvironmentScanner: View {
    @EnvironmentObject var bleScanner: BLEScanner
    @EnvironmentObject var viewModel: EnvironmentViewModel
    @Environment(\.horizontalSizeClass) var sizeClass
    
    @State var showDetail: Bool = false
    
    @State var selectedManufacturers: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}
    @State var minimumRSSI: Float = -100
    
    @GestureState var scaling: CGFloat = 1.0
    @State var finalScale: CGFloat = 1.0
    @State var currentScale: CGFloat = 0.0
    @State var dragAmount = CGSize.zero
    
    static var sheetTransition: AnyTransition {
        let insertion = AnyTransition.move(edge: .bottom)
            .combined(with: .opacity)
        let removal = AnyTransition.move(edge: .bottom)
            .combined(with: .opacity)
        
        return .asymmetric(insertion: insertion, removal: removal)
    }
    

    var presentedDevices: [BLEDevice] {
        var devices = self.bleScanner.deviceList.sorted(by: {$0.id < $1.id})
        
        //Filter out all unselected devices
        devices = devices.filter {self.selectedManufacturers.contains($0.manufacturer.rawValue.capitalized)}
        
        devices = devices.filter { self.minimumRSSI <= -100 ? true : $0.lastRSSI >= self.minimumRSSI}
        
//
        return devices
    }
    
    var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { (amount) in
                self.currentScale = amount - 1
            }
            .onEnded { amount in
                if self.finalScale + self.currentScale < 1.0 {
                    self.finalScale = 1.0
                }else {
                    self.finalScale += self.currentScale
                }
                
                self.currentScale = 0
            }
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { (dragValue) in
                if self.finalScale > 1.0 {
                    self.dragAmount = dragValue.translation
                }
            }
            .onEnded { (dragValue) in
            
            }
    }
    
    func environmentSize(for geometry: GeometryProxy) -> CGSize {
        let scale = (self.finalScale + self.currentScale)
        let size = geometry.size.width < geometry.size.height ? geometry.size.width : geometry.size.height
        return CGSize(width: size * 0.8 * scale, height: size * 0.8 * scale)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    HStack {
                        FilterSettings(selectedManufacturers: self.$selectedManufacturers, minimumRSSI: self.$minimumRSSI)
                        .padding()
                    }
                    Spacer(minLength: 20.0)
                }
                
                
                //Scanner view
//                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                ZStack {
                    
                        GeometryReader { geometry  in
                            ZStack {
                                BackgroundView(minRSSI: self.$minimumRSSI)

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
                        .padding()
                        .frame(width: self.environmentSize(for: geometry).width, height: self.environmentSize(for: geometry).height, alignment: .top)
                        .offset(self.dragAmount)
                        .highPriorityGesture(self.zoomGesture)
                        .highPriorityGesture(self.dragGesture)

                }
                Spacer()
            }
            
        }
    
        
        
    }
    
    func angle(for device: BLEDevice) -> CGFloat {
        let devices = self.presentedDevices
        let angle: CGFloat = 0
        let angleStep = 2 * CGFloat.pi / CGFloat(devices.count)
        
        if let idx = devices.firstIndex(of: device) {
            return angle + angleStep * CGFloat(idx.distance(to: 0))
        }
        
        return angle
    }
    
    func position(for rssi: Float, size: CGSize, angle: CGFloat) -> CGPoint {
        let circleSize: CGFloat = {
            if size.width > size.height {
                return size.height
            }
            return size.width
        }()
        
        let rssiMax = CGFloat(self.minimumRSSI)
        let distance: CGFloat = {
            if CGFloat(rssi) < rssiMax {
                return circleSize/2
            }
            
            return circleSize/2 * CGFloat(abs(rssi))/rssiMax
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
        
        var filterButton: some View {
            Button(action: {
                self.showManufacturerSelection.toggle()
            }, label:  {
                Image(systemName: "line.horizontal.3.decrease.circle")
                    .imageScale(.large)
            })
            .popoverSheet(isPresented: self.$showManufacturerSelection, content: {
                ManfucaturerSelection(selectedManufacturers: self.$selectedManufacturers, isShown: self.$showManufacturerSelection)
            })
        }
        
        var sliderRange = Float(-100.0)...Float(0.0)
        
        
        var body: some View {
            Group {
                
                
                self.filterButton
                
                Slider(value: self.$minimumRSSI,in: self.sliderRange)
                    .frame(maxWidth: 200.0)
                
                if self.minimumRSSI <= -100 {
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
//    @ObservedObject var viewModel: EnvironmentViewModel
    
    @Binding var minRSSI: Float
    
    var body: some View {
        
        GeometryReader { geometry in
           ZStack(alignment: .center) {
                
                Circle()
                    .fill(self.circleColor)
                    .frame(width: geometry.size.width * 0.1, height: geometry.size.height * 0.1, alignment: .center)
            
                Text("\(String(format: "%.2f", self.minRSSI * 0.1)) dBm")
                    .position(x: geometry.size.width/2, y: geometry.size.smaller * 0.05 + geometry.size.height/2 + 10.0)
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width/4, height: geometry.size.height/4, alignment: .center)
                Text("\(String(format: "%.2f", self.minRSSI * 0.25)) dBm")
                    .position(x: geometry.size.width/2, y: geometry.size.smaller * 0.125 + geometry.size.height/2 + 10.0)
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width/2, height: geometry.size.height/2, alignment: .center)
                
                Text("\(String(format: "%.2f", self.minRSSI * 0.5)) dBm")
                    .position(x: geometry.size.width/2, y:geometry.size.smaller * 0.25 + geometry.size.height/2 + 10.0)
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width * 0.75, height: geometry.size.height * 0.75, alignment: .center)
                
                Text("\(String(format: "%.2f", self.minRSSI * 0.75)) dBm")
                    .position(x: geometry.size.width/2, y: geometry.size.smaller * 0.375 + geometry.size.height/2 + 10.0)
                
                Circle()
                    .stroke(self.circleColor, style: self.strokeStyle)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                
                Text("\(String(format: "%.2f", Float(self.minRSSI))) dBm")
                    .position(x: geometry.size.width/2, y: geometry.size.smaller * 0.5 + geometry.size.height/2 + 10.0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
           .opacity(0.75)
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
    
    
    var imageName: String {
        if self.device.manufacturer == .seemoo {
            return "seemoo"
        }
        
        return self.device.deviceType?.string ?? "BluetoothDevice"
    }
    
    var scaling: CGFloat {
        if sizeClass == .compact {
            return 0.5
        }

        return 1.0
    }
    
    var iconColor: Color {
        if self.device.isActive {
            return Color("isSendingColor")
        }else {
            return Color("notSendingColor")
        }
    }
    
    var body: some View {
        VStack {
            
            if device.name != nil {
                Text(device.name! + " ")
                    .frame(minWidth: 100, maxWidth: 150)
                    .multilineTextAlignment(.center)
                    .animation(.none)
            }
            
            if self.device.deviceType != nil {
                Text("\(device.deviceType!.string) ")
                    .frame(width: 100)
                    .multilineTextAlignment(.center)
                    .animation(.none)
                
            }else {
                Text(self.device.manufacturer.rawValue + " ")
                    .frame(width: 100)
                    .animation(.none)
            }
            
            
            Image(self.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 45.0)
                .foregroundColor(self.iconColor)
                
                
            Text(String(format: "RSSI: %0.0f dBm", Float(device.lastRSSI)))
                .frame(width: 100.0)
                .font(.footnote)
                .animation(.none)
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
