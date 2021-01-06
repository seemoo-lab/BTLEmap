//
//  DeviceDetailView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 03.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import SwiftUI
import BLETools
import BLEDissector

struct DeviceDetailView: View {
    @ObservedObject var device: BLEDevice
    var showInModal = false
    @Binding var isShown: Bool
    @State var displayedAdvertisementTypes = BLEAdvertisment.AppleAdvertisementType.allCases
    @State var showAdvertisementFilter = false
    
    @State var showShareSheet = false
    
    var advertisements: [BLEAdvertisment] {
        guard self.displayedAdvertisementTypes.count != BLEAdvertisment.AppleAdvertisementType.allCases.count else {return device.advertisements}
        
        return device.advertisements.filter { (advertisment) -> Bool in
            advertisment.advertisementTypes.contains(where: {self.displayedAdvertisementTypes.contains($0)})
        }
    }
    
    init(device: BLEDevice, showInModal: Bool=false, isShown: Binding<Bool>?=nil) {
        if isShown != nil {
            self._isShown = isShown!
        }else {
            self._isShown = Binding.constant(true)
        }
        
        self.device = device
        self.showInModal = showInModal
    }
    
    var filterButton: some View {
        Button(action: {
            self.showAdvertisementFilter.toggle()
        }, label: {
            Image(systemName: "line.horizontal.3.decrease.circle")
                .imageScale(.large)
                .padding()
        })
            .popoverSheet(isPresented: $showAdvertisementFilter, content: {
                AdvertisementTypeFilterView(selectedAdvertisementTypes: self.$displayedAdvertisementTypes, isShown: self.$showAdvertisementFilter)
            })
        
        
        //            .popover(isPresented: $showAdvertisementFilter, content: {
        //                AdvertisementTypeFilterView(selectedAdvertisementTypes: self.$displayedAdvertisementTypes, isShown: self.$showAdvertisementFilter)
        //            })
        
    }
    
    var dismissButton: some View {
        Button(action: {
            self.isShown = false
        }) {
            Text("Btn_Dismiss")
                .padding()
        }
    }
    
    var csvURL: URL {
        let csvString = self.device.advertisementCSV
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let csvURL = URL(fileURLWithPath: documentPath).appendingPathComponent("exported.csv")
        try! csvString.write(to: csvURL, atomically: true, encoding: .utf8)
        //                let nsURL = NSURL.fileURL(withPath: csvURL.path)
        return csvURL
    }
    
    var exportButton: some View {
        
        Button(action: {
            #if targetEnvironment(macCatalyst)
            export(file: self.csvURL)
            #else
            share(items: [self.csvURL])
            #endif
        }) {
            Image(systemName: "square.and.arrow.up")
                .imageScale(.large)
                .padding()
        }
        
        
    }
    
    
    var body: some View {
        VStack {
            if showInModal {
                VStack {
                    HStack {
                        Spacer()
                        
                        Button("Dismiss") {
                            withAnimation {
                                self.isShown.toggle()
                            }
                        }
                        .padding()
                        
                    }
//                    .background(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.lightGray).background(Color.background))
                    
                    DetailViewContent(device: device, isShown: $isShown, filteredAdvertisements: self.advertisements)
                        .environmentObject(RowColors())
                        .navigationBarTitle(Text(device.name ?? device.id), displayMode: .inline)
                        .navigationBarItems(leading: self.filterButton, trailing: HStack {
                            self.exportButton
                            self.dismissButton
                        })

                }
                .background(Color.background)
            }else {
                DetailViewContent(device: device, isShown: $isShown, filteredAdvertisements: self.advertisements)
                    .environmentObject(RowColors())
                    .navigationBarTitle(Text(device.name ?? device.id))
                    .navigationBarItems(trailing:
                        HStack{
                            self.filterButton
                            self.exportButton
                    })
                
            }
            
        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }
    
    
    
    struct DetailViewContent: View {
        @ObservedObject var device: BLEDevice
        @EnvironmentObject var rowColors: RowColors
        @Binding var isShown: Bool
        @Environment(\.horizontalSizeClass) var sizeClass
        
        var filteredAdvertisements: [BLEAdvertisment]
        
        var services: [BLEService] {
            device.services.sorted(by: {$0.commonName < $1.commonName})
        }
        
        var advertisements: [BLEAdvertisment] {
            let advertisements = self.filteredAdvertisements
            
            return advertisements.sorted(by: {$0.receptionDates.first! > $1.receptionDates.first!})
        }
        
        var advertisementTypes: [BLEAdvertisment.AppleAdvertisementType] {
            return Array(Set(filteredAdvertisements.flatMap{$0.advertisementTypes}.filter{$0 != .unknown})).sorted(by: {$0.description < $1.description})
        }
        
        var deviceInformation: some View {
            Group {
                VStack {
                    if self.device.name != nil {
                        Text(self.device.id)
                    }
                    
                    self.device.macAddress.map { (macAddress) in
                        Text(macAddress.addressString) + Text(" (\(String(describing: macAddress.addressType)))")
                    }
                    
                    HStack {
                        
                        Text(self.device.deviceModel?.modelDescription ?? "Unknown model")
                        
                        
                        if self.device.osVersion != nil {
                            Divider()
                            
                            Text(self.device.osVersion!)
                                .font(.callout)
                        }
                        
                        
                        if self.device.wiFiOn != nil {
                            Divider()
                            
                            Text(self.device.wiFiOn! ? "WiFi: On" : "WiFi Off")
                                .font(.callout)
                        }
                        
                        
                    }.frame(height: 20)
                }
                
                HStack {
                    Text(String(format: "RSSI: %0.0f dBm", Float(self.device.lastRSSI)))
                    Divider()
                    Text("Connectable: \(self.device.connectable ? "true" : "false")")
                }
                .frame(height: 20)
                
            }
        }
        
        func generateServiceRow(for service: BLEService) -> some View {
            let characteristics = service.characteristics.sorted(by: {$0.commonName < $1.commonName})
            return HStack {
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(Color(red: 0.5, green: 0.306, blue: 0.055))
                    .frame(width: 5.0)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(service.commonName)
                    SelectableTextView(text: service.uuidString, presentationMode: .bytes)
                    .padding([.top,.bottom], 6.0)
                    
                    ForEach(characteristics, id: \.self) { (characteristic: BLECharacteristic) in
                        
                        self.generateCharacteristicsView(for: characteristic)
                    }
                }
            }
        }
        
        func generateCharacteristicsView(for characteristic: BLECharacteristic) -> some View {
            Group {
                Text("\t" + characteristic.commonName)
                Text("\t" + characteristic.uuid.uuidString).font(.system(.caption, design: .monospaced))
                if characteristic.value != nil {
                    Text("\t\t" + characteristic.valueDescription)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(Color("Highlight"))
                    
                }
                //                String(data: characteristic.value!, encoding: .utf8)?.map { value in
                //                    Text(value)
                //                }
            }
        }
        
        var body: some View {
            VStack {
                self.deviceInformation
                
                VStack {
                    List {
                        if self.services.count > 0 {
                            Section(header: Text("Title_supoorted_services")) {
                                ForEach(self.services, id: \.self) { service in
                                    self.generateServiceRow(for: service)
                                }
                            }
                        }
                        
                        if self.device.manufacturer == .apple {
                            Section(header: Text("Title_advertisementTypes")) {
                                ForEach(self.advertisementTypes, id: \.self) { advType  in
                                    Text(advType.description)
                                }
                            }
                        }
                        
                        Section(header: Text("Title_advertisements_received")) {
                            ForEach(self.advertisements) { advertisement in
                                AdvertisementRow(advertisement: advertisement)
                            }
                        }
                    }
                }
            }
        }
    }
}

class RowColors: ObservableObject {
    struct CustomColor {
        var red: Double
        var green: Double
        var blue: Double
        
        func darken() -> CustomColor {
            return CustomColor(red: red * 0.9, green: green * 0.9, blue: blue * 0.9)
        }
    }
    var currentColor = CustomColor(red: 0.5, green: 0.306, blue: 0.055)
    /// UUID String to Color
    var colors = [String : Color]()
    func color(for uuidString: String) -> Color {
        if let color = colors[uuidString] {
            return color
        }else {
            let c = currentColor.darken()
            let color = Color(red: c.red, green: c.green, blue: c.blue)
            colors[uuidString] = color
            self.currentColor = c
            return color
        }
    }
}

//struct AdvertismentRow: View {
//    @ObservedObject var advertisement: BLEAdvertisment
//    
//    var decodedAdvertisement: String {
//        guard let advertisementTLV = advertisement.advertisementTLV else {return NSLocalizedString("txt_not_decodable", comment: "Info text")}
//        
//        let decodedDicts = advertisementTLV.getTypes().compactMap{(try? AppleBLEDecoding.decoder(forType: UInt8($0)).decode(advertisementTLV.getValue(forType: $0)!))}
//        
//        let dictDescriptions =  decodedDicts.map(description(for:)).map{$0.sorted().joined()}.joined(separator: "\n\n")
//        
//        return dictDescriptions
//    }
//    
//    var dateFormatter: DateFormatter {
//        let df = DateFormatter()
//        df.timeStyle = .short
//        df.dateStyle = .short
//        
//        return df
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading) {
//            AdvertisementRawManufacturerData(advertisement: advertisement)
//            Text(self.decodedAdvertisement)
//            HStack {
//                Text("Received \(advertisement.numberOfTimesReceived) times")
//                Spacer()
//                Text("\(dateFormatter.string(from: advertisement.receptionDates.first!)) - \(dateFormatter.string(from: advertisement.receptionDates.last!))")
//            }
//        }
//    }
//    
//    func description(for dictionary: [String: Any]) -> [String] {
//        return dictionary.map { (key, value) -> String in
//            if let data = value as? Data {
//                return "\(key): \t\t\(data.hexadecimal.separate(every: 8, with: " "))\n"
//            }
//
//            if let array = value as? [Any] {
//                return "\(key): \t \(array.map{String(describing: $0)}) \n"
//            }
//
//            return "\(key):\t\t\(value)\n"
//        }
//    }
//}



struct AttributedText: UIViewRepresentable {
    var attributedString: NSAttributedString
    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        //        label.attributedText = self.attributedString
        return label
    }
    
    func updateUIView(_ uiView:  UILabel, context: Context) {
        uiView.attributedText = attributedString
        uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        uiView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
}
