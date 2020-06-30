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
    @EnvironmentObject var filters: AppliedFilters
    
    @State var showRSSIScanner = false
    
    init() {
//        #if DEBUG
//        let df = DateFormatter()
//        df.dateFormat = "mm:ss.SSS"
//        print("\(df.string(from: Date() )) Redrawing list")
//        #endif
    }
    
    var devices: [BLEDevice] {
//        self.scanner.deviceList.sorted(by: {$0.id < $1.id})
        return self.scanner.deviceList.filter(with: self.filters)
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
            print("Device list appeared")
        }
    }

}


struct MainScannerView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceListView()
    }
}
