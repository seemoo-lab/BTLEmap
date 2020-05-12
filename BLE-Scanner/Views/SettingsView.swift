//
//  SettingsView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 18.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import BLETools
import ZIPFoundation

struct SettingsView: View {
    @EnvironmentObject var bleScanner: BLEScanner
    @Environment(\.presentationMode) var presentation
    
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
    
    @State var timeoutInterval: String = String(format: "%0.0f", UserDefaults.standard.timeoutInterval/60.0) {
        didSet {
//            self.bleScanner.timeoutInterval = self.timeoutInterval
            if let timeInterval = TimeInterval(self.timeoutInterval) {
                self.bleScanner.timeoutInterval = timeInterval * 60.0
                UserDefaults.standard.timeoutInterval = timeInterval * 60.0
            }
        }
    }
    
    @State var autoConnectToDevices:Bool = UserDefaults.standard.autoconnectToDevices
    
    @State var showRSSIRecorder: Bool = false
    
    /// When set to true the BLE receiver selection is shown
    @State var showReceiverSelection: Bool = false
    @State var loading = false
    
    var receiverActionsheet: PopSheet {
        PopSheet(title: Text("Title_Select_BLE_receiver"), message: Text("Message_Select_BLE_Receiver"), buttons: BLEScanner.Receiver.allCases.map{ t in
            PopSheet.Button.default(Text(t.name), action: {
                withAnimation {
                    self.bleScanner.receiverType = t
                }
                })
            }
            +
            [PopSheet.Button.cancel()]
        )
    }
    
    var settingsList: some View {
        List {
            Toggle(isOn: self.$scanning, label: {Text("Sts_ble_scanning")})
            
            Toggle(isOn: self.$filterDuplicates, label: {Text("Sts_filter_duplicates")})
                .disabled(!self.scanning)
            
            Toggle(isOn: self.$timeoutDevices, label: {Text("Sts_devices_can_timeout")})
                .disabled(!self.scanning)
            
            Toggle(isOn: $autoConnectToDevices, label: {Text("Sts_autoconnect")})
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
            
            Button(action: {
                self.showReceiverSelection.toggle()
            }, label: {
                HStack {
                    Text("Sts_Receiver_Selection")
                    Spacer()
                    Text(self.bleScanner.receiverType.name)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
            })
            .popSheet(isPresented: self.$showReceiverSelection, content: {
                       self.receiverActionsheet
                   })
            
            Button(action: {
                self.pcapExport()
            }, label: {
                Text("Sts_export_to_pcap")
            })
            
        }
        .navigationBarTitle(Text("Ttl_settings"))
        .sheet(isPresented: self.$showRSSIRecorder, content: {
            RSSIRecorderView(isShown: self.$showRSSIRecorder).environmentObject(self.bleScanner)
        })
    }
    
    var dismissButton: some View {
        Button("Btn_Dismiss") {
            self.presentation.wrappedValue.dismiss()
        }
        .padding()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack (spacing: 0) {
                HStack {
                    Spacer()
                    self.dismissButton
                }
                
                NavigationView {
                    self.settingsList
                }
                
            }
            .navigationViewStyle(StackNavigationViewStyle())
            
            if !bleScanner.connectedToReceiver {
                ConnectingView().environmentObject(self.bleScanner)
            }
            
            if self.loading {
                ZStack(alignment: .center) {
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                     
                    ActivitySpinner(animating: self.$loading, color: UIColor.white, style: .large)
                        .frame(alignment: .center)
                }
             }
             
        }
        .onAppear {
            self.scanning = self.bleScanner.scanning
        }
        .onDisappear {
            self.bleScanner.autoconnect = self.autoConnectToDevices
            self.bleScanner.scanning = self.scanning
            
            self.bleScanner.filterDuplicates = self.filterDuplicates
            UserDefaults.standard.filterDuplicates = self.filterDuplicates
            
            self.bleScanner.devicesCanTimeout = self.timeoutDevices
            UserDefaults.standard.timeoutDevices = self.timeoutDevices
            
            if let timeInterval = TimeInterval(self.timeoutInterval) {
                self.bleScanner.timeoutInterval = timeInterval * 60.0
                UserDefaults.standard.timeoutInterval = timeInterval * 60.0
            }
            
            UserDefaults.standard.BLEreceiverType = self.bleScanner.receiverType
            
            UserDefaults.standard.autoconnectToDevices = self.autoConnectToDevices
        }
    }
    
    func pcapExport() {
        self.loading = true
        //Generate PCAP data
        DispatchQueue.global(qos: .userInitiated).async {
            
            let pcapData = PcapExport.export(advertisements: self.bleScanner.advertisements)
            
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!
            let pcapURL = documentsURL.appendingPathComponent("exported.pcap")
            let zipURL = documentsURL.appendingPathComponent("exported.pcap.zip")
            
            do {
                //Write pcap to file
                try pcapData.write(to: pcapURL)
                
                //Compress pcap file
                let fileManager = FileManager.default
                try fileManager.zipItem(at: pcapURL, to: zipURL)
                
                //Delete pcap file
                try fileManager.removeItem(at: pcapURL)
                
            }catch {
                //TODO: Show error
                DispatchQueue.main.async {
                    self.loading = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self.loading = false
                guard let source = UIApplication.shared.windows.first?.rootViewController else {
                    return
                }
                
                let controller = UIDocumentPickerViewController(url: zipURL, in: .exportToService)
                controller.shouldShowFileExtensions = true
                
                
                if let userFolder = NSSearchPathForDirectoriesInDomains(.userDirectory, .userDomainMask, true).first {
                    controller.directoryURL = URL(fileURLWithPath: userFolder)
                }
                
                var presentationController = source
                while presentationController.presentedViewController != nil {
                    presentationController = presentationController.presentedViewController!
                }
                
                
                controller.popoverPresentationController?.sourceView = presentationController.view
                presentationController.present(controller, animated: true)
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
    
    var BLEreceiverType: BLETools.BLEScanner.Receiver {
        set(v) {
            self.set(v.rawValue, forKey: "BLE_Receiver")
        }
        get {
            return BLETools.BLEScanner.Receiver(rawValue: self.integer(forKey: "BLE_Receiver")) ?? .coreBluetooth
        }
    }
    
    var autoconnectToDevices: Bool {
        set(v) {
            self.set(v, forKey: "AutoconnectToDevices")
        }get {
            self.bool(forKey: "AutoconnectToDevices")
        }
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    @State static var isShown: Bool = true
    static var bleScanner = BLEScanner()
    
    static var previews: some View {
        SettingsView().environmentObject(bleScanner)
    }
}
