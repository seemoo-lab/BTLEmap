//
//  SettingsView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 18.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import BLETools

struct SettingsView: View {
    @EnvironmentObject var bleScanner: BLEScanner
    
    @State var scanning = true {
        didSet {
            self.bleScanner.scanning = self.scanning
        }
    }
    
    @State var filterDuplicates = UserDefaults.standard.filterDuplicates {
        didSet {
            self.bleScanner.filterDuplicates = self.filterDuplicates
            UserDefaults.standard.filterDuplicates = self.filterDuplicates
        }
    }
    
    @State var timeoutDevices = UserDefaults.standard.timeoutDevices {
        didSet {
            self.bleScanner.devicesCanTimeout = self.timeoutDevices
            UserDefaults.standard.timeoutDevices = self.timeoutDevices
        }
    }
    
    @State var timeoutInterval: String = String(format: "%0.0f", UserDefaults.standard.timeoutInterval) {
        didSet {
//            self.bleScanner.timeoutInterval = self.timeoutInterval
            if let timeInterval = TimeInterval(self.timeoutInterval) {
                self.bleScanner.timeoutInterval = timeInterval * 60.0
                UserDefaults.standard.timeoutInterval = timeInterval * 60.0
            }
        }
    }
    
    @State var showRSSIRecorder: Bool = false
    
    
    var body: some View {
        NavigationView {
            List {
                Toggle(isOn: self.$scanning, label: {Text("Sts_ble_scanning")})
                
                Toggle(isOn: self.$filterDuplicates, label: {Text("Sts_filter_duplicates")})
                    .disabled(!self.scanning)
                
                Toggle(isOn: self.$timeoutDevices, label: {Text("Sts_devices_can_timeout")})
                    .disabled(!self.scanning)
                
                HStack {
                    Text("Sts_timeout_interval")
                    Spacer()
                    TextField("Sts_timeout_interval", text: self.$timeoutInterval)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                        .disabled(!self.scanning)
                    
                    Text("min")
                }
                
                Button(action: {
                    self.showRSSIRecorder.toggle()
                }, label: {
                    HStack {
                        Text("Sts_showrssi")
                    }
                })
                
            }
            .navigationBarTitle(Text("Ttl_settings"))
            .sheet(isPresented: self.$showRSSIRecorder, content: {
                RecordAdvertisementsView().environmentObject(self.bleScanner)
            })
        }
    .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            self.scanning = self.bleScanner.scanning
        }
        .onDisappear {
            self.bleScanner.scanning = self.scanning
            
            self.bleScanner.filterDuplicates = self.filterDuplicates
            UserDefaults.standard.filterDuplicates = self.filterDuplicates
            
            self.bleScanner.devicesCanTimeout = self.timeoutDevices
            UserDefaults.standard.timeoutDevices = self.timeoutDevices
            
            if let timeInterval = TimeInterval(self.timeoutInterval) {
                self.bleScanner.timeoutInterval = timeInterval * 60.0
                UserDefaults.standard.timeoutInterval = timeInterval * 60.0
            }
        }
    }
        
}

extension UserDefaults {
    
    var filterDuplicates: Bool {
        set(v) {
            self.set(v, forKey: "filterDuplicates")
            self.synchronize()
        }
        get {
            self.bool(forKey: "filterDuplicates")
        }
    }
    
    
    var timeoutDevices: Bool {
        set(v) {
            self.set(v, forKey: "BLEtimeoutDevice")
            self.synchronize()
        }
        get {
            self.bool(forKey: "BLEtimeoutDevice")
        }
    }
    
    var timeoutInterval: TimeInterval {
        set(v) {
            self.set(v, forKey: "BLETimeoutInterval")
            self.synchronize()
        }
        get {
            if self.double(forKey: "BLETimeoutInterval") == 0.0 {
                return 5
            }else {
               return self.double(forKey: "BLETimeoutInterval")
            }
        }
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
