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
    @EnvironmentObject var scanner: BLEScanner_SwiftUI
    
    var body: some View {
        NavigationView {
            List(self.scanner.devices) { device in
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
    @State var bleDevice: BLEDevice
    
    var body: some View {
        VStack(alignment: .leading) {
            //Device UUID
            Text(bleDevice.id)
            // Manufacturer
            
            Spacer()
            
            if bleDevice.name != nil {
                HStack {
                    Text(bleDevice.name!)
                        .font(.callout)
                    Text(bleDevice.manufacturer.name)
                        .font(.callout)
                }
            }else {
                Text(bleDevice.manufacturer.name)
                    .font(.callout)
            }
            
            
        }
        
    }
}

struct MainScannerView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceListView()
    }
}
