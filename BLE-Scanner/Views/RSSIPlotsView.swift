//
//  RSSIPlotsView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 14.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import BLETools

struct RSSIPlotsView: View {
    @EnvironmentObject var bleScanner: BLEScanner
    @State var deviceColors = [BLEDevice: Color]()
    //Filters
    @State var selectedManufacturers: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}
    @State var minRSSI: Float = -100
    @State var scrollAutomatically: Bool = true
    @State var showFilterSettings = false
    
    var devices: [BLEDevice] {
        self.bleScanner.deviceList.filter({$0.lastRSSI >= self.minRSSI && self.selectedManufacturers.contains($0.manufacturer.rawValue.capitalized)}).sorted(by: {$0.id < $1.id})
     }
    
    var deviceList: some View {
        List(self.devices) { device in
            BLEDeviceRow(bleDevice: device, fixedIconColor: self.color(for: device))
        }
    }
    
    var devicesPlotInfo: [RSSIMultiDevicePlot.DevicePlotInfo] {
        self.devices.map({RSSIMultiDevicePlot.DevicePlotInfo(deviceId: $0.id, plotColor: self.color(for: $0), rssis: self.rssis(for: $0))})
    }
    
    var filterSettings: some View {
        Group {
            VStack {
                FilterSettings(selectedManufacturers: self.$selectedManufacturers, minimumRSSI: self.$minRSSI)
            }
        }
    }
    
    var body: some View {
        GeometryReader{ g in
            VStack {
                
                HStack {
                    Toggle("Ttl_Scroll_automatically", isOn: self.$scrollAutomatically)
                    Spacer()
                    Button(action: {
                        self.showFilterSettings.toggle()
                    }, label:  {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .imageScale(.large)
                    })
                        .popoverSheet(isPresented: self.$showFilterSettings, content: {
                            self.filterSettings
                        })
                }.padding()
                
                HStack() {
                    self.deviceList
                        .frame(width: g.size.width * 0.33, height: g.size.height)
                        .background(Color.red)
                    
                    RSSIMultiDevicePlot(plotInfo: self.devicesPlotInfo, height: g.size.height, width: g.size.width * 0.66, scroll: self.$scrollAutomatically)
                        .frame(width: g.size.width * 0.66, height: g.size.height)
                }
            }
            .frame(width: g.size.width, height: g.size.height)
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
    
    func color(for device: BLEDevice) -> Color {
//        if let color = self.deviceColors[device] {
//            return color
//        }
        
        let deviceIndex = (self.devices.firstIndex(of: device) ?? 0) % 9
        let color = Color("h\(deviceIndex)")
//        self.deviceColors[device] = color
        return color
    }
    
    struct RSSIDate {
        let rssi: Float
        let date: Date
    }
}

extension RSSIPlotsView {
    
    
    struct RSSIMultiDevicePlot: View {
        @Environment(\.horizontalSizeClass) var sizeClass
        @Binding var scrollAutomatically: Bool
        var plotInfo: [DevicePlotInfo]
        
        var dateRange: ClosedRange<Date>
        var height: CGFloat
        var width: CGFloat
        
        /// The width of one time interval (1s) in the graph
        var scaleTimeInterval: CGFloat = 30
        
        init(plotInfo: [DevicePlotInfo], height: CGFloat, width: CGFloat, scroll: Binding<Bool>) {
            self.plotInfo = plotInfo
            //Padding on top
            self.height = height - 20
            self.width = width
            self._scrollAutomatically = scroll
            self.scaleTimeInterval = width / 20
            var minDate = Date.distantFuture
            var maxDate = Date.distantPast
            
            if plotInfo.count == 0 {
                dateRange = Date()...(Date().addingTimeInterval(10))
                return
            }
            
            plotInfo.forEach { (dpi) in
                if let d = dpi.rssis.first?.date,
                    d < minDate {
                    minDate = d
                }
                if let d = dpi.rssis.last?.date,
                    d > maxDate {
                    maxDate = d
                }
            }
            
            dateRange = minDate...maxDate
        }
        
        var scrollWidth: CGFloat {
            return CGFloat(self.dateRange.upperBound.timeIntervalSinceReferenceDate - self.dateRange.lowerBound.timeIntervalSinceReferenceDate) * scaleTimeInterval
        }
        
        
        
        /// Y value for the line
        /// - Parameter line: index of the line
        /// - Returns: Y value for the float
        func lineY(lineNum line: Int) -> CGFloat {
            let dHeight = self.height / CGFloat(100)
            return self.height - dHeight * CGFloat(line * 10)
        }
        
        func y(for rssi: Float) -> CGFloat {
            let dHeight = self.height / CGFloat(100)
            let y = dHeight * CGFloat(abs(rssi))
            return y
        }
        
        func x(for date: Date) -> CGFloat {
            let ti = date.timeIntervalSince( self.dateRange.lowerBound )
            let x = CGFloat(ti) * self.scaleTimeInterval
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
        
        /// The RSSI Plots for each device
        var plots: some View {
            Group {
                ForEach(self.plotInfo, id: \.deviceId) { (devicePI) in
                    Path { path in
                        devicePI.rssis.enumerated().forEach({ rssiElement in
                            let x = self.x(for: rssiElement.element.date)
                            let y = self.y(for: rssiElement.element.rssi)
                            
                            if rssiElement.offset == 0 {
                                path.move(to: CGPoint(x: x, y: 0))
                            }
                            
                            path.addLine(to: CGPoint(x: x, y: y))
                        })
                    }.stroke(devicePI.plotColor)
                }
            }
        }
    
        
        var body: some View {
            VStack {
                
                ZStack {
                    ScrollView(.horizontal) {
                        ZStack {
                            self.horizontalLines
                            self.plots
                        }
                        .frame(width: self.scrollWidth > self.width ? self.scrollWidth : self.width, height: self.height)
                        .offset(x: self.scrollAutomatically && self.scrollWidth > self.width ? -(self.scrollWidth - self.width) : 0, y: 0)
                    }
                    .disabled(self.scrollAutomatically)
                    
                    self.yAxisText
                }.frame(width: self.width, height: self.height)
            }

        }
        
        struct DevicePlotInfo {
            let deviceId: String
            let plotColor: Color
            let rssis: [RSSIDate]
        }
    }
    
}

struct RSSIPlotsView_Previews: PreviewProvider {
    @State static var scanner = BLEScanner()
    
    static var previews: some View {
        RSSIPlotsView().environmentObject(self.scanner)
    }
}
