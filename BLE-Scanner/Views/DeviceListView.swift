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
           
        }
    }

}


struct MainScannerView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceListView()
    }
}
