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
    
    var body: some View {
        NavigationView {
            List(self.scanner.deviceList) { device in
                NavigationLink(destination: DeviceDetailView(device: device)) {
                    BLEDeviceRow(bleDevice: device)
                }
            }
            .navigationBarTitle(Text("Nav_Bar_Scanner_title"))
            .navigationBarItems(trailing: Button(action: {
                self.scanner.scanning.toggle()
            }, label: {
                if self.scanner.scanning {
                    Text("Btn_stop_scanning")
                }else {
                    Text("Btn_start_scanning")
                }
                
            }))
        }
        .onAppear {
            guard self.scanner.scanning == false else {return}
            self.scanner.scanning = true
        }
    }
    
    func checkForBluetoothPermission() {
        
    }
    
}

struct BLEDeviceRow: View {
    @ObservedObject var bleDevice: BLEDevice
    
    var deviceTypeString: String {
        switch self.bleDevice.deviceType {
        case .AirPods:
            return "AirPods"
        case .appleEmbedded:
            return "Embedded"
        case .iMac:
            return "iMac"
        case .AppleWatch:
            return "Apple Watch"
        case .iPad: return "iPad"
        case .iPod: return "iPod"
        case .iPhone: return "iPhone"
        case .macBook: return "MacBook"
        case .other:
            if self.bleDevice.manufacturer == .apple {
                return "Apple"
            }
            return "Other"
        case .Pencil: return "Pencil"
        case .none: return "Other"
        }
    }
    
    var iconColor: Color {
        if self.bleDevice.lastUpdate.timeIntervalSinceNow > -1.1 {
            return Color("isSendingColor")
        }else {
            return Color("notSendingColor")
        }
    }
    
    var deviceImage: some View {
        Group {
            Image(self.deviceTypeString)
                .resizable()
                .aspectRatio(contentMode: .fit)
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
