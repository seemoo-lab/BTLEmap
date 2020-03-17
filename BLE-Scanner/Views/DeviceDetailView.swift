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
import AppleBLEDecoder

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
        .background(Color.red)
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
                NavigationView {
                    DetailViewContent(device: device, isShown: $isShown, filteredAdvertisements: self.advertisements)
                        .navigationBarTitle(Text(device.name ?? device.id), displayMode: .inline)
                        .navigationBarItems(leading: self.filterButton, trailing: HStack {
                            self.exportButton
                            self.dismissButton
                        })
                }
                .navigationViewStyle(StackNavigationViewStyle())
                
            }else {
                DetailViewContent(device: device, isShown: $isShown, filteredAdvertisements: self.advertisements)
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
        @Binding var isShown: Bool
        @Environment(\.horizontalSizeClass) var sizeClass
        
        var filteredAdvertisements: [BLEAdvertisment]
        
        var services: [String] {
            if let services = device.peripheral.services {
                return services.map{$0.uuid.description}
            }
            return []
        }
        
        var advertisements: [BLEAdvertisment] {
            let advertisements = self.filteredAdvertisements
            
            return advertisements.reversed()
        }
        
        var advertisementTypes: [BLEAdvertisment.AppleAdvertisementType] {
            return Array(Set(filteredAdvertisements.flatMap{$0.advertisementTypes}.filter{$0 != .unknown})).sorted(by: {$0.description < $1.description})
        }
        
        var deviceInformation: some View {
            Group {
                VStack {
                    Text(self.device.id)
                    
                    HStack {
                        
                        Text(self.device.modelNumber ?? "Unknown model")
                        
                        
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
                    Text("RSSI \(self.device.lastRSSI.intValue) dBm")
                    Divider()
                    Text("Connectable: \(self.device.connectable ? "true" : "false")")
                }
                .frame(height: 20)
                
            }
        }
        
        var body: some View {
            VStack {
                self.deviceInformation
                
                VStack {
                    List {
                        if self.services.count > 0 {
                            Section(header: Text("Title_advertised_services")) {
                                ForEach(self.services, id: \.self) { service in
                                    Text(service)
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
                                AdvertismentRow(advertisement: advertisement)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AdvertismentRow: View {
    @ObservedObject var advertisement: BLEAdvertisment
    
    var decodedAdvertisement: String {
        guard let advertisementTLV = advertisement.advertisementTLV else {return NSLocalizedString("txt_not_decodable", comment: "Info text")}
        
        let decodedDicts = advertisementTLV.getTypes().compactMap{(try? AppleBLEDecoding.decoder(forType: UInt8($0)).decode(advertisementTLV.getValue(forType: $0)!))}
        
        let dictDescriptions =  decodedDicts.map(description(for:)).map{$0.sorted().joined()}.joined(separator: "\n\n")
        
        return dictDescriptions
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            AdvertisementRawManufacturerData(advertisement: advertisement)
            Text(self.decodedAdvertisement)
            HStack {
                Text("Received \(advertisement.numberOfTimesReceived) times")
            }
        }
    }
    
    func description(for dictionary: [String: Any]) -> [String] {
        return dictionary.map { (key, value) -> String in
            if let data = value as? Data {
                return "\(key): \t\t\(data.hexadecimal.separate(every: 8, with: " "))\n"
            }
            
            if let array = value as? [Any] {
                return "\(key): \t \(array.map{String(describing: $0)}) \n"
            }
            
            return "\(key):\t\t\(value)\n"
        }
    }
}

struct AdvertisementRawManufacturerData: View {
    @ObservedObject var advertisement: BLEAdvertisment
    @State var copied: Bool = false
    
    var manufacturerDataString: String {
        
        if let attributedString = self.advertisement.dataAttributedString {
            return attributedString.string
        }
        
        if let manufacturerData = self.advertisement.manufacturerData {
            return manufacturerData.hexadecimal.separate(every: 8, with: " ")
        }
        return "Empty"
    }
    
    var manufacturerDataText: some View {
        Group {
            if self.advertisement.advertisementTLV != nil {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Apple").bold()
                        ForEach(self.advertisement.advertisementTLV!.tlvs, id: \.type) { tlv in
                            HStack {
                                BLEAdvertisment.AppleAdvertisementType(rawValue: tlv.type).map({
                                Text("\($0.description) ")
                                    .bold()
                                })
                            }
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        ForEach(self.advertisement.advertisementTLV!.tlvs, id: \.type) { tlv in
                            
                            HStack {
                                Text (String(format: "0x%02X", UInt8(tlv.type)))
                                    .font(Font.system(.body, design: .monospaced))
                                    
                                Text (String(format: " 0x%02X: ", UInt8(tlv.length)))
                                    .font(Font.system(.body, design: .monospaced))
                                
                                Text ("0x" + tlv.value.hexadecimal.separate(every: 8, with: " ").uppercased())
                                        .font(Font.system(.body, design: .monospaced))
                                
                            }
                        }
                    }
                }

            }else {
                Text(self.advertisement.manufacturerData?.hexadecimal.separate(every: 8, with: " ") ?? "Empty")
            }
        }
    }
    
    var copyButton: some View {
        //Copy Button
        ZStack {
            
            if !self.copied {
            Button(action: {
                UIPasteboard.general.string = self.advertisement.manufacturerData?.hexadecimal ?? ""
                withAnimation {self.copied = true}
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (_) in
                    withAnimation {self.copied = false}
                }
            }, label: {
                ZStack {
                    Circle().fill(Color("ButtonBackground"))
                        .frame(width: 50.0, height: 50.0, alignment: .center)
                    Image(systemName: "doc.on.clipboard")
                        .accentColor(Color.white)
                }
                
            })
                .transition(.opacity)
//                .opacity(self.copied ? 0.0 : 1.0 )

            }
            
            if self.copied {
                ZStack {
                    RoundedRectangle(cornerRadius: 5.0)
                        .fill(Color("ButtonBackground"))
                        .frame(width: 100.0, height: 50.0)
                    Text("Info_copied")
                }
                .transition(.opacity)
//                .opacity(self.copied ? 1.0: 0.0)

            }
            
        }
    }
    
    var body: some View {
        HStack {
            self.manufacturerDataText
            
            Spacer()
            
            self.copyButton
        }
        
    }
}

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
