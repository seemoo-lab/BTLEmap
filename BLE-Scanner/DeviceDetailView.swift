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
import Apple_BLE_Decoder

struct DeviceDetailView: View {
    @ObservedObject var device: BLEDevice
    var showInModal = false
    @Binding var isShown: Bool
    @State var displayedAdvertisementTypes = BLEAdvertisment.AppleAdvertisementType.allCases
    @State var showAdvertisementFilter = false
    
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
    
    var body: some View {
        Group {
            if showInModal {
                NavigationView {
                    DetailViewContent(device: device, isShown: $isShown, filteredAdvertisements: self.advertisements)
                        .navigationBarTitle(Text(device.name ?? device.id), displayMode: .inline)
                        .navigationBarItems(leading:
                            Button(action: {
                                self.showAdvertisementFilter.toggle()
                            }, label: {
                                Text("Btn_filter_advertisements")
                            })
                                .popover(isPresented: $showAdvertisementFilter, content: {
                                    AdvertisementTypeFilterView(selectedAdvertisementTypes: self.$displayedAdvertisementTypes, isShown: self.$showAdvertisementFilter)
                                })
                            
                            ,trailing: Button(action: {
                                self.isShown = false
                            }) {
                                Text("Btn_Dismiss")
                                    .padding()
                        } )
                }
                .navigationViewStyle(StackNavigationViewStyle())
                
            }else {
                DetailViewContent(device: device, isShown: $isShown, filteredAdvertisements: self.advertisements)
                    .navigationBarTitle(Text(device.name ?? device.id))
                    .navigationBarItems(leading:
                        Button(action: {
                            self.showAdvertisementFilter.toggle()
                        }, label: {
                            Text("Btn_filter_advertisements")
                        })
                            .popover(isPresented: $showAdvertisementFilter, content: {
                                AdvertisementTypeFilterView(selectedAdvertisementTypes: self.$displayedAdvertisementTypes, isShown: self.$showAdvertisementFilter)
                            })
                )
                   
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
        
        var body: some View {
            VStack {
                Spacer()
                Text(device.id)
                Text(device.modelNumber ?? "Unknown model")
                
                HStack {
                    Text("RSSI \(device.lastRSSI.intValue) dBm")
                }
                
                VStack {
                    List {
                        if self.services.count > 0 {
                            Section(header: Text("Title_advertised_services")) {
                                ForEach(self.services, id: \.self) { service in
                                    Text(service)
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
                        ForEach(self.advertisement.advertisementTLV!.tlvs, id: \.type) { tlv in
                            HStack {
                                Text("").font(.system(.body, design: .monospaced))
                                BLEAdvertisment.AppleAdvertisementType(rawValue: tlv.type).map({
                                Text($0.description)
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
            Button(action: {
                UIPasteboard.general.string = self.advertisement.manufacturerData?.hexadecimal ?? ""
                self.copied = true
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (_) in
                    self.copied = false
                }
            }, label: {
                ZStack {
                    Circle().fill(Color("ButtonBackground"))
                        .frame(width: 50.0, height: 50.0, alignment: .center)
                    Image(systemName: "doc.on.clipboard")
                }
                
            })
                .accentColor(Color.white)
                .opacity(self.copied ? 0.0 : 1.0 )
                .animation(.linear)
            
            ZStack {
                RoundedRectangle(cornerRadius: 5.0)
                    .fill(Color("ButtonBackground"))
                    .frame(width: 100.0, height: 50.0)
                Text("Info_copied")
            }
            .opacity(self.copied ? 1.0: 0.0)
            .animation(.linear)
            
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
