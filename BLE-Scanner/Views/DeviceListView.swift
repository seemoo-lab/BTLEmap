//
//  ContentView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 02.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import BLETools
import CoreBluetooth

struct DeviceListView: View {
    @EnvironmentObject var scanner: BLEScanner
    
    @State var showRSSIScanner = false
    
    
    var devices: [BLEDevice] {
//        self.scanner.deviceList.sorted(by: {$0.id < $1.id})
        return self.scanner.deviceList
    }
    
    var navigationBarItems: some View {
                
        Button(action: {
            print("Show settings")
            NotificationCenter.default.post(name: NSNotification.Name.App.showPreferences, object: nil)
        }, label: {
            Image(systemName: "ellipsis.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25.0, height: 25.0)
                .padding([.top, .bottom])
        })

    }
    
    var body: some View {
        NavigationView {
            List(self.devices) { device in
                NavigationLink(destination: DeviceDetailView(device: device)) {
                    BLEDeviceRow(bleDevice: device)
                }
            }
            .navigationBarTitle(Text("Nav_Bar_Scanner_title"), displayMode: .inline)
            .navigationBarItems(trailing: self.navigationBarItems)
        }
        .onAppear {
            guard self.scanner.scanning == false else {return}
            self.scanner.scanning = true
        }
    }

}

struct BLEDeviceRow: View {
    @ObservedObject var bleDevice: BLEDevice
    
    var fixedIconColor: Color?
    
    var imageName: String {
        if self.bleDevice.manufacturer == .seemoo {
            return "seemoo"
        }
        return self.bleDevice.deviceModel?.deviceType.string ?? BLEDeviceModel.DeviceType.other.string
    }
    
    var iconColor: Color {
        guard self.fixedIconColor == nil else {
            return fixedIconColor!
        }
        
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
    
    var body: some View {
        HStack {
            self.deviceImage
            
            VStack(alignment: .leading) {
                //Device UUID
                Text(bleDevice.id)
                    .font(.callout)
                // Manufacturer
                
                Spacer()
                
                bleDevice.deviceModel.map({
                    Text($0.modelDescription)
                })
                
                HStack {
                    bleDevice.name.map {
                        Text($0)
                            .font(.callout)
                    }
                    
                    Text(bleDevice.manufacturer.name)
                        .font(.callout)
                }
            
                
                HStack {
                    bleDevice.osVersion.map {
                        Text($0)
                            .font(.callout)
                    }
                    
                    bleDevice.wiFiOn.map {
                        Text($0 ? "WiFi: On" : "WiFi Off")
                            .font(.callout)
                    }
                }
            }
        }
    }
}

struct MainScannerView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceListView()
    }
}
