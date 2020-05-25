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
import Combine

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
    
    @State var pcapNotification: AnyCancellable?
    
    @State var errorInfo: ErrorInfo?
    
    
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
    
    var settingsSection: some View {
        Section(header: Text("Scan settings")) {
            

            SettingsToggleRow(value: self.$scanning, title: "Sts_ble_scanning", description: "If off BTLEmap will no longer scan for advertisements")
            
            SettingsToggleRow(value: self.$filterDuplicates, title: "Sts_filter_duplicates", description: "Uses less energy if on. RSSI readings will be updated less often.")
            
            
            SettingsToggleRow(value: self.$timeoutDevices, title: "Sts_devices_can_timeout", description: "If on, the devices will be removed from the list after the number of minutes defined")
            
            HStack {
                Text("Sts_timeout_interval")
                Spacer()
                TextField("Sts_timeout_interval", text: self.$timeoutInterval)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .disabled(!self.scanning)
                
                Text("min")
            }
            
            SettingsToggleRow(value: self.$autoConnectToDevices, title: "Sts_autoconnect", description: "Connect automatically to every BLE device in range to perform device identification. Will reduce scanning speed if on. Might cause undefined behavior on nearby BLE devices")
            

            
            VStack(alignment: .leading) {
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
                
                Text("Select which input for BLE messages should be used")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }

        }
    }
    
    var importExportSection: some View {
        Section(header: Text("Import/Export")) {
            Button(action: {
                self.pcapExport()
            }, label: {
                Text("Sts_export_to_pcap")
            })
            
            Button(action: {
                self.loading = true
                UIKitBridge.shared.importPcapFile()
            }) {
                Text("Sts_import_from_pcap")
            }
        }
    }
    
    var additionalFeaturesSections: some View {
        Section(header: Text("Additional features")) {
            Button(action: {
                self.showRSSIRecorder.toggle()
            }, label: {
                HStack {
                    Text("Sts_showrssi")
                }
            })
            .popSheet(isPresented: self.$showReceiverSelection, content: {
                self.receiverActionsheet
            })
        }
    }
    
    var settingsList: some View {
        List {
            
            self.settingsSection

            self.importExportSection
                
            self.additionalFeaturesSections
            
        }
        .listStyle(GroupedListStyle())
        .environment(\.horizontalSizeClass, .regular)
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
                NavigationView {
                    self.settingsList
                        .navigationBarItems(trailing: self.dismissButton)
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
        .alert(item: self.$errorInfo, content: { (errorInfo) -> Alert in
            Alert(title: Text(errorInfo.errorTitle), message: Text(errorInfo.errorMessage), dismissButton: Alert.Button.cancel())
        })
        .onAppear {
            self.scanning = self.bleScanner.scanning
            
            //Subscribe to notification publisher
            self.pcapNotification = NotificationCenter.default.publisher(for: Notification.Name.App.importingPcapFinished).sink { (notification) in
                self.loading = false
                
                if let error = notification.userInfo?["error"] {
                    //Error on pcap import
                    self.errorInfo = ErrorInfo(errorMessage: String(describing: error), errorTitle: "Import failed")
                }else {
                    //Pcap import finished
                    self.scanning = false
                    self.presentation.wrappedValue.dismiss()
                }
                
                
            }
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
            self.pcapNotification?.cancel()
        }
    }
    
    func pcapExport() {
        self.loading = true
        UIKitBridge.shared.exportPcapFile { (result) in
            self.loading = false
            switch result {
            case .failure(let error):
                self.errorInfo = ErrorInfo(errorMessage: String(describing: error), errorTitle: NSLocalizedString("pcap_export_failed_title", comment: "Error title"))
            case .success(_):
                return
            }
        }
    }
    
    struct ErrorInfo: Identifiable {
        var id: String {
            return errorMessage
        }
        
        let errorMessage: String
        let errorTitle: String
    }
        
}

struct SettingsToggleRow: View {
    @Binding var value: Bool
    var title: LocalizedStringKey
    var description: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Toggle(isOn: self.$value, label: {Text(self.title)})
            Text(self.description)
                .foregroundColor(Color.gray)
                .font(.footnote)
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
