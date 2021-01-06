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
    
    @EnvironmentObject var filters: AppliedFilters
    @State var showDetail: Bool = false
    
    @GestureState var scaling: CGFloat = 1.0
    @State var minRSSI: Float = -100
    @State var finalScale: CGFloat = 1.0
    @State var currentScale: CGFloat = 0.0
    @State var dragAmount = CGSize.zero
    @State var lastOffset = CGSize.zero
    
    @State var detailDevice: BLEDevice?
    
    static var sheetTransition: AnyTransition {
        let insertion = AnyTransition.move(edge: .bottom)
            .combined(with: .opacity)
        let removal = AnyTransition.move(edge: .bottom)
            .combined(with: .opacity)
        
        return .asymmetric(insertion: insertion, removal: removal)
    }
    
    @State var presentedDevices: [BLEDevice] = []
    
    #if TARGET_OS_MACCATALYST
    static let updateInterval = 0.3
    #else
    static let updateInterval = 0.3
    #endif
    /// Update timer. On every call the view should update. A direct update takes up too much energy
    @State var updateTimer = Timer.publish(every: updateInterval, on: .main, in: .common).autoconnect()
    
    var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { (amount) in
                self.currentScale = amount - 1
            }
            .onEnded { amount in
                if self.finalScale + self.currentScale < 1.0 {
                    self.finalScale = 1.0
                    self.dragAmount = CGSize.zero
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
                    self.dragAmount = CGSize(width: self.lastOffset.width + dragValue.translation.width, height: self.lastOffset.height + dragValue.translation.height)
                }
            }
            .onEnded { (dragValue) in
                self.lastOffset = self.dragAmount
            }
    }
    
    func environmentSize(for geometry: GeometryProxy) -> CGSize {
        let scale = (self.finalScale + self.currentScale)
        let size = geometry.size.width < geometry.size.height ? geometry.size.width : geometry.size.height
        return CGSize(width: size * 0.9 * scale, height: size * 0.9 * scale)
    }
    
    func environmentScanner(geometry: GeometryProxy) -> some View {
        //Scanner view
        //                ScrollView([.horizontal, .vertical], showsIndicators: true) {
        
        return 
            GeometryReader { geometry  in
                ZStack {
                    BackgroundView(minRSSI: self.filters.minRSSI)
                    
                    //Draw devices
                    ForEach(self.presentedDevices) { device in
                        Button(action: {
                            withAnimation(.easeIn){
                                self.detailDevice = device
                                self.viewModel.detailDevice = device
                                self.showDetail = true
                            }
                        }, label: {
                            DeviceOnCircleView(device: device)
                        })
                        .buttonStyle(PlainButtonStyle())
                        .position(self.position(for: device.lastRSSI, size: geometry.size, angle: self.angle(for: device)))
                    }
                }
                .animation(.linear)
                
                
            }
            .padding(50)
            .offset(self.dragAmount)
            .scaleEffect(self.finalScale + self.currentScale)
            .highPriorityGesture(self.zoomGesture)
            .highPriorityGesture(self.dragGesture)
            .clipped()
        
    }

    var body: some View {
        GeometryReader { geometry  in
            ZStack {
                BackgroundView(minRSSI: self.filters.minRSSI)
                
                //Draw devices
                ForEach(self.presentedDevices) { device in
                    Button(action: {
//                            withAnimation(.easeIn){
                        self.detailDevice = device
                        self.viewModel.detailDevice = device
                        self.showDetail = true
                        
//                            }
                    }, label: {
                        DeviceOnCircleView(device: device)
                    })
                    .buttonStyle(PlainButtonStyle())
                    .position(self.position(for: device.lastRSSI, size: geometry.size, angle: self.angle(for: device)))
                }
            }
            .animation(.linear)
            
            
        }
        .padding(50)
        .offset(self.dragAmount)
        .scaleEffect(self.finalScale + self.currentScale)
        .highPriorityGesture(self.zoomGesture)
        .highPriorityGesture(self.dragGesture)
        .clipped()
        .onReceive(self.updateTimer) { (timer) in
            self.update()
        }
        .modalView(self.$showDetail, modal: {
            DeviceDetailView(device: self.viewModel.detailDevice!, showInModal: true, isShown: self.$showDetail)
        })
        
    }
    
    func update() {
        self.presentedDevices = self.bleScanner.deviceList.filter(with: self.filters)
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
        
        let rssiMax = CGFloat(self.filters.minRSSI)
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
    
}



struct EnvironmentScanner_Previews: PreviewProvider {
    @State static var filters = AppliedFilters()
    static var bleScanner = BLEScanner()
    
    static var previews: some View {
        EnvironmentScanner(presentedDevices: [])
            .environmentObject(bleScanner)
    }
}

struct BackgroundView: View {
    let strokeStyle = StrokeStyle(lineWidth: 2.0)
    let circleColor = Color.gray
//    @ObservedObject var viewModel: EnvironmentViewModel
    
    var minRSSI: Float
    
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
        return self.device.imageName()
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
    
    var deviceName: String? {
        if let name = self.device.name {
            return String("\(name)  ")
        }
        
        return nil
    }
    
    var modelName: String? {
        if let modelName = self.device.deviceModel?.modelDescription {
            return String("\(modelName)  ")
        }
        return nil
    }
    
    var manufacturer: String {
        self.device.manufacturer.rawValue.capitalized + " " + NSLocalizedString("device", comment: "")
    }
    
    
    var body: some View {
        VStack(alignment: .center) {
            
            if device.name != nil {
                deviceName.map { (string) in
                    Text(string)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .animation(.none)
                        .padding([.leading, .trailing], 2.0)
                }
                
            }
            
            if self.device.deviceModel != nil {
                modelName.map { (string) in
                    Text(string)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .animation(.none)
                        .padding([.leading, .trailing], 2.0)
                }
                
            }else {
                Text(self.manufacturer)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .animation(.none)
                    .padding([.leading, .trailing], 2.0)
            }
            
            
            Image(self.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 35.0)
                .foregroundColor(self.iconColor)
                
                
            Text(String(format: "RSSI: %0.0f dBm", Float(device.lastRSSI)))
                .font(.footnote)
                .animation(.none)
                .padding([.leading, .trailing], 2.0)
        }
        .frame(maxWidth: 130.0)
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
