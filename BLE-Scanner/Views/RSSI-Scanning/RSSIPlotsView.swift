//
//  RSSIPlotsView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 14.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import BLETools

class RSSIGraphViewModel: NSObject, ObservableObject {
    var deviceColors = [BLEDevice: Color]()
    var selectedDevices = Set<BLEDevice>()
    
    func color(for device: BLEDevice) -> Color {
        
        guard selectedDevices.count == 0 || selectedDevices.contains(device) else {
            return Color.gray.opacity(0.7)
        }
        
        if let color = self.deviceColors[device] {
            return color
        }
        
        let deviceIndex = (self.deviceColors.count) % 9
        let color = Color("h\(deviceIndex)")
        self.deviceColors[device] = color
        return color
    }
}

struct RSSIPlotsView: View {
    @EnvironmentObject var bleScanner: BLEScanner
    @EnvironmentObject var viewModel: RSSIGraphViewModel
    @EnvironmentObject var filters: AppliedFilters
    @Environment(\.horizontalSizeClass) var sizeClass
    
    @State var scrollAutomatically: Bool = true
    @State var showFilterSettings = false
    
    #if TARGET_OS_MACCATALYST
    static let updateInterval = 0.1
    #else
    static let updateInterval = 0.1
    #endif
    
    /// Update timer. On every call the view should update. A direct update takes up too much energy
    let updateTimer = Timer.publish(every: updateInterval, on: .main, in: .common).autoconnect()
    
    @State var devices: [BLEDevice] = []
    @State var devicesPlotInfo: [RSSIMultiDevicePlot.DevicePlotInfo] = []
    
    
    var deviceList: some View {
        List(self.devices) { device in
            Button(action: {
                if self.viewModel.selectedDevices.contains(device) {
                    self.viewModel.selectedDevices.remove(device)
                }else {
                    self.viewModel.selectedDevices.insert(device)
                }
            }, label: {
                BLEDeviceRow(bleDevice: device, fixedIconColor: self.viewModel.color(for: device))
                    
            })
        }
        
    }
    

    func settings(for width: CGFloat) -> some View {
        Group {
            if width < 500  {
                VStack {
                    Toggle("Ttl_Scroll_automatically", isOn: self.$scrollAutomatically)
                        .frame(maxWidth: 250)
                        .padding([.leading, .trailing])
                }
            }else {
                HStack {
                    Toggle("Ttl_Scroll_automatically", isOn: self.$scrollAutomatically)
                                           .frame(maxWidth: 250)
                                           .padding([.leading, .trailing])
                        .environmentObject(self.filters)
                    
                    Spacer()
                }
            }
            
        }
    }
    
    var body: some View {
        GeometryReader{ g in
            VStack {
                self.settings(for: g.size.width)
                
                GeometryReader {g2 in
                    HStack() {
                        self.deviceList
                            .frame(width: g2.size.width * 0.33, height: g2.size.height)
                            .background(Color.red)
                        
                        Divider()
                        
                        RSSIMultiDevicePlot(
                            plotInfo: self.devicesPlotInfo,
                            startDate: self.bleScanner.scanStartTime,
                            height: g2.size.height,
                            width: g.size.width * 0.66,
                            scroll: self.$scrollAutomatically)
                            .frame(width: g2.size.width * 0.66, height: g2.size.height)
                    }
                }
            }
            .frame(width: g.size.width, height: g.size.height)
        }
        .onAppear(perform: {
            DispatchQueue.main.async {
                self.updateGraph()
            }
        })
        .onReceive(updateTimer) { (timer) in
            self.updateGraph()
        }
    }
    
    /// Get an array of RSSI values for a device. The values contain a date when they have been received
    /// - Parameter device: BLE Device
    /// - Returns: An array RSSI values with the reception date
    func rssis(for device: BLEDevice) -> [RSSIDate] {
        var rssiDates = device.advertisements.flatMap { (advertisement) -> [RSSIDate] in
            advertisement.receptionDates.enumerated().compactMap { (element) -> RSSIPlotsView.RSSIDate? in
                if element.offset < advertisement.rssi.count {
                    return RSSIDate(rssi: advertisement.rssi[element.offset].floatValue, date: element.element)
                }
                return nil
            }
        }
        
        rssiDates.sort(by: {$0.date < $1.date})
        
        return rssiDates
    }
    
    func applyFilters(to device: BLEDevice) -> Bool {
        guard self.filters.selectedManufacturers.contains(device.manufacturer.rawValue.capitalized) else {return false}
        
        return self.filters.minRSSI == -100 ||  device.lastRSSI > self.filters.minRSSI
    }
    
    func updateGraph() {
            
        self.devices = self.bleScanner.deviceList.filter(with: self.filters)
        self.devicesPlotInfo = self.devices.map({RSSIMultiDevicePlot.DevicePlotInfo(deviceId: $0.id, plotColor: self.viewModel.color(for: $0), rssis: $0.allRSSIs)})
    }
    
    struct RSSIDate {
        let rssi: Float
        let date: Date
    }
    
    typealias RSSITime = (time: TimeInterval, rssi: Float)
}

extension RSSIPlotsView {
    
    
    struct RSSIMultiDevicePlot: View {
        @Environment(\.horizontalSizeClass) var sizeClass
        @Binding var scrollAutomatically: Bool
        var plotInfo: [DevicePlotInfo]
        
        var dateRange: ClosedRange<Date>
        var height: CGFloat
        var width: CGFloat
        let dHeight: CGFloat
        let xLineHeight: CGFloat
        
        /// The width of one time interval (1s) in the graph
        var scaleTimeInterval: CGFloat = 30
        
        init(plotInfo: [DevicePlotInfo], startDate: Date, height: CGFloat, width: CGFloat, scroll: Binding<Bool>) {
            self.plotInfo = plotInfo
            //Padding on top
            self.height = height - 20
            self.width = width
            self.dHeight = self.height / CGFloat(120)
            self.xLineHeight = self.height - 10*self.dHeight
            
            self._scrollAutomatically = scroll
            self.scaleTimeInterval = width / 20
            
            dateRange = startDate...Date()
        }
        
        var scrollWidth: CGFloat {
            return CGFloat(self.dateRange.upperBound.timeIntervalSinceReferenceDate - self.dateRange.lowerBound.timeIntervalSinceReferenceDate) * scaleTimeInterval
        }
        
        
        
        /// Y value for the line
        /// - Parameter line: index of the line
        /// - Returns: Y value for the float
        func lineY(lineNum line: Int) -> CGFloat {
            return dHeight * CGFloat(line * 10)
        }
        
        func y(for rssi: Float) -> CGFloat {
            let y = dHeight * CGFloat(abs(rssi))
            return y
        }
        
        func x(for time: TimeInterval) -> CGFloat {
            let x = CGFloat(time) * self.scaleTimeInterval
            return x
        }
        
        /// Horizontal Lines for the graph
        var horizontalLines: some View {
            ZStack(alignment: .leading) {
                // Levels -0dBm ... -100dBm
                ForEach(0..<11) { line in
                    
                  // Group for Path and Text
                  Group {
                    Path { path in
                        
                        let y = self.lineY(lineNum: line)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: self.scrollWidth > self.width ? self.scrollWidth : self.width, y: y))
                        
                    }.stroke(line == 0 ? Color.black : Color.gray)
                    //Text for the
                    
                  }
                }
            }
        }
        
        var yAxisText: some View {
            ZStack(alignment: .leading) {
                ForEach(0..<11) { (line) in
                    HStack {
                        Text("-\(line * 10)dBm")
//                        Spacer()
                    }
                    .position(CGPoint(x: 40, y: self.lineY(lineNum: line) + CGFloat(10)))
                }
            }
        }
        
        var xAxisLines: some View {
            let hLines = Array(stride(from: 0, to: Int(self.scrollWidth > self.width ? self.scrollWidth : self.width), by: Int(self.scaleTimeInterval * 5)))
            return ZStack {
                ForEach(hLines, id: \.self) { v in
                    Group {
                        Path { path in
//                            let x = CGFloat(v) * self.scaleTimeInterval
                            let x = CGFloat(v)
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x:x, y: self.xLineHeight))
                        }
                        .stroke(Color.gray)
                        
                        HStack {
                            Text("\(v / Int(self.scaleTimeInterval))s")
                        }
                        .position(CGPoint(x: CGFloat(v) + 5, y: self.xLineHeight + self.dHeight))
                    }
                }
            }
        }
        
        /// The RSSI Plots for each device
        var plots: some View {
            Group {
                ForEach(self.plotInfo, id: \.deviceId) { (devicePI) in
                    Path { path in
                        devicePI.rssis.enumerated().forEach({ rssiElement in
                            let x = self.x(for: rssiElement.element.time)
                            let y = self.y(for: rssiElement.element.rssi)
                            
                            if rssiElement.offset == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            }else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        })
                    }
                .stroke(devicePI.plotColor, style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round, miterLimit: 0, dash: [], dashPhase: 0))
                }
            }
        }
    
        
        var body: some View {
            VStack {
                
                ZStack {
                    ScrollView(.horizontal) {
                        ZStack {
                            self.horizontalLines
                            self.xAxisLines
                            self.plots
                        }
                        .frame(width: self.scrollWidth > self.width ? self.scrollWidth : self.width, height: self.height)
                        .offset(x: self.scrollAutomatically && self.scrollWidth > self.width ? -(self.scrollWidth - self.width) : 0, y: 0)
                    }
                    .disabled(self.scrollAutomatically)
                    
                    self.yAxisText
                }
                .frame(width: self.width, height: self.height)
                
            }

        }
        
        struct DevicePlotInfo {
            let deviceId: String
            let plotColor: Color
            let rssis: [RSSITime]
        }
    }
    
}

struct RSSIPlotsView_Previews: PreviewProvider {
    @State static var scanner = BLEScanner()
    static var filters = AppliedFilters()
    
    static var previews: some View {
        RSSIPlotsView()
            .environmentObject(self.scanner)
            .environmentObject(self.filters)
    }
}
