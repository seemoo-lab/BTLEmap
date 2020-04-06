//
//  AdvertisementManudfacturerDataView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 03.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import SwiftUI

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
