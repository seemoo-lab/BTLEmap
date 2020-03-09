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
    @State var scrollAutomatically = true
    

    
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
                    DetailViewContent(device: device, isShown: $isShown)
                    .navigationBarTitle(Text(device.name ?? device.id), displayMode: .inline)
                    .navigationBarItems(trailing: Button(action: {
                        self.isShown = false
                    }) {
                        Text("Btn_Dismiss")
                            .padding()
                    } )
                }
                .navigationViewStyle(StackNavigationViewStyle())
                
            }else {
                DetailViewContent(device: device, isShown: $isShown)
                .navigationBarTitle(Text(device.name ?? device.id))
            }
            
        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }
    
    struct DetailViewContent: View {
        @ObservedObject var device: BLEDevice
        @Binding var isShown: Bool
        @Environment(\.horizontalSizeClass) var sizeClass
        
        
        var services: [String] {
            if let services = device.peripheral.services {
                return services.map{$0.uuid.description}
            }
            return []
        }
        
        var advertisements: [BLEAdvertisment] {
            let advertisements = device.advertisements
            
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
    
    var manufacturerDataString: String {
        if let attributedString = self.advertisement.dataAttributedString {
            return attributedString.string
        }
        
        if let manufacturerData = self.advertisement.manufacturerData {
            return manufacturerData.hexadecimal.separate(every: 8, with: " ")
        }
        return "Empty"
    }
    
    var body: some View {
        Text(self.manufacturerDataString)
            .font(.system(.body, design: .monospaced))
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
