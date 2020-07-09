//
//  AdvertisementRow.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 03.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import BLEDissector
import BLETools
import SwiftUI
import CoreBluetooth

struct AdvertisementRow: View {
    @ObservedObject var advertisement: BLEAdvertisment

    var isDecodedAdvertisement: Bool {
        self.advertisement.advertisementTLV != nil
    }
    
    @State var highlightedRange: ClosedRange<Int>?

    var decodedAdvertisements: [DecodedAdvType] {
        let types = self.advertisement.advertisementTypes

        return types.compactMap { (advType) -> DecodedAdvType? in
            guard
                let advData = self.advertisement.advertisementTLV?.getValue(
                    forType: advType.rawValue)
            else { return nil }

            let decoder = try? AppleBLEDecoding.decoder(forType: UInt8(advType.rawValue))
            let decoded = try? decoder?.decode(advData)

            return DecodedAdvType(type: advType, data: advData, description: decoded)
        }
    }
    
    var advChannel: String {
        if let channel = self.advertisement.channel {
            return String(describing: channel)
        }else {
            return "unknown"
        }
    }

    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .short

        return df
    }
    
    var servicesUUIDView: some View {
        self.advertisement.serviceUUIDs.map { (services) in
            AccordeonView(title: Text("Services")) {
                VStack {
                    ForEach(0..<services.count) { (serviceIdx) in
                        SelectableTextView(text: services[serviceIdx].description, presentationMode: .bytes)
                    }
                    
                }
            }
        }
    }
    
    var serviceData: [DissectedEntry]? {
        self.advertisement.dissectedServiceData
    }
    

    
    var dissectedManufacturerDataView: some View {
        Group {
            self.advertisement.dissectedManufacturerData.map { entry in
                AccordeonView(title: Text(entry.name)) {
                    VStack {
                        RawDataView(data: entry.data, highlightedRange: self.highlightedRange)
                        
                        ForEach(0..<entry.subEntries.count) { idx in
                            self.viewForDissectedServiceData(serviceData: entry.subEntries[idx], parent: nil)
                        }
                    }
                }
            }
        }
    }
    
    var serviceDataView: some View {
        return self.serviceData.map { serviceData in
            VStack(alignment:.leading) {
                AccordeonView(title: Text("Service data")) {
                    VStack {
                        ForEach(0..<serviceData.count) { (serviceIdx) in
                            self.viewForDissectedServiceData(serviceData: serviceData[serviceIdx], parent: nil)
                        }
                    }

                }
            }
        }
    }
    
    
    
    func viewForDissectedEntries(_ dissectedEntries: [DissectedEntry], with parentEntry: DissectedEntry) -> some View {
        AccordeonView(title: Text(parentEntry.name)) {
            
            RawDataView(data: parentEntry.data, highlightedRange: self.highlightedRange)
            
            VStack(alignment: .leading) {
                ForEach(0..<dissectedEntries.count) { (serviceIdx) in
                    self.viewForDissectedServiceData(serviceData: dissectedEntries[serviceIdx], parent: parentEntry, coloredBackground: (serviceIdx%2)==0)
                }
            }
        }
    }
    
    func viewForDissectedServiceData(serviceData: DissectedEntry, parent: DissectedEntry?, coloredBackground: Bool = false) -> some View {
        Group {
            if serviceData.subEntries.count == 0 {
                Group {
                    // List Data
                    AnyView(
                        HStack {
                            Text(serviceData.name + ": ")
                            Text(serviceData.valueDescription)
                            Spacer()
                        }
                    )
                    serviceData.explanatoryText.map({
                        Text($0)
                            .italic()
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                    })
                    
                    
                }
                .padding([.bottom, .top], 4)
                .contentShape(Rectangle())
                .background( coloredBackground ? Color.lightGray : nil)
                .onTapGesture {
//                    let lowerBound = (parent?.byteRange.lowerBound ?? 0) + serviceData.byteRange.lowerBound
                    let lowerBound = serviceData.byteRange.lowerBound
                    self.highlightedRange = lowerBound...(lowerBound + serviceData.byteRange.count - 1)
                }
                
            }else {
                AnyView(
                    self.viewForDissectedEntries(serviceData.subEntries, with: serviceData)
                )
            }
        }
    }

    var body: some View {
        VStack {
            
            self.servicesUUIDView
            
            if self.serviceData != nil  {
                self.serviceDataView
            }
            
            self.dissectedManufacturerDataView
            

            HStack {
                Text("Channel: \(self.advChannel)")
                Spacer() 
            }
            
            
            HStack {
                Text("Received \(advertisement.numberOfTimesReceived) times")
                Spacer()
                Text(
                    "\(dateFormatter.string(from: advertisement.receptionDates.first!)) - \(dateFormatter.string(from: advertisement.receptionDates.last!))"
                )
            }
        }
    }

    struct RawDataView: View {
        var byteArray: [UInt8]
        let byteString: NSMutableAttributedString

        init(data: Data, highlightedRange: ClosedRange<Int>?) {
            
            self.byteArray = Array(data)
            
            let bytes = self.byteArray.reduce("0x") { (result, byte) -> String in result + String(format: " %02X", byte)}
            
            self.byteString = NSMutableAttributedString(string: bytes, attributes:
                [NSAttributedString.Key.font : UIFont.monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular),
                 NSAttributedString.Key.foregroundColor: UIColor(named: "TextColor") ?? UIColor.white
            ])
            
            if let highlighted = highlightedRange {
                let start = 2 + highlighted.lowerBound * 3
                let length = highlighted.count * 3
                let textRange =  NSMakeRange(start, length)
                self.byteString
                    .addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.green, range: textRange)
            }
           
        }

        var body: some View {
            VStack(alignment: .leading) {
                SelectableTextView(text: nil, attributedString: self.byteString, presentationMode: .attributedString)
            }

        }
    }
}

struct AdvertisementRow_Previews: PreviewProvider {
    static var advertisementNearby = BLEAdvertisment(
        advertisementData: [
            "kCBAdvDataChannel": 37,
            "kCBAdvDataIsConnectable": true,
            "kCBAdvDataManufacturerData": "0x4c0010054B1CC6E7E6".hexadecimal!,
    ], rssi: NSNumber(value: -30.0), peripheralUUID: UUID())

    static var previews: some View {
        AdvertisementRow(advertisement: self.advertisementNearby)
    }
}
