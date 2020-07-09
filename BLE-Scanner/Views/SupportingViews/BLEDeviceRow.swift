//
//  BLEDeviceRow.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 06.05.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import SwiftUI
import CoreBluetooth

struct BLEDeviceRow: View {
    @ObservedObject var bleDevice: BLEDevice
    
    var fixedIconColor: Color?
    
    var imageName: String {
        return self.bleDevice.imageName() 
    }
    
    var iconColor: Color {
        guard self.fixedIconColor == nil else {
            return fixedIconColor!
        }
        
//        return Color("notSendingColor")
        
        if self.bleDevice.isActive {
            return Color("isSendingColor")
        }else {
            return Color("notSendingColor")
        }
    }
    
    var deviceImage: some View {
        Group {
            Image(self.imageName)
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
                .frame(height: 35.0)
                .foregroundColor(self.iconColor)
                .padding(.trailing)
        }
    }
    
    var deviceTitle: String {
        if let deviceName = self.bleDevice.name {
            return deviceName
        }else if let macAddress = self.bleDevice.macAddress {
            return macAddress.addressString
        }
        return self.bleDevice.id
    }
    
    var deviceInfo: String? {
        guard self.bleDevice.name != nil else {return nil}
        
        if let macAddress = self.bleDevice.macAddress {
            return macAddress.addressString
        }
        
        return self.bleDevice.id
    }
    
    var body: some View {
        HStack {
            self.deviceImage
            
            VStack(alignment: .leading) {
                //Device title
                Text(self.deviceTitle)
                    .font(.subheadline)

                
                Spacer()
                
                self.deviceInfo.map {
                     Text($0)
                         .font(.caption)
                 }
                 
                
                bleDevice.deviceModel.map({
                    Text($0.modelDescription)
                        .font(.footnote)
                })
                
 
                Text(bleDevice.manufacturer.name)
                .font(.caption)
            
                
                HStack {
                    bleDevice.osVersion.map {
                        Text($0)
                            .font(.caption)
                    }
                    
                    bleDevice.wiFiOn.map {
                        Text($0 ? "WiFi: On" : "WiFi Off")
                            .font(.caption)
                    }
                }
            }
        }
    }
}

