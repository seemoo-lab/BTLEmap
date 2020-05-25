//
//  MainTabbarView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 03.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import BLETools
//import AWDLScanner

struct MainView: View {
    @State var currentViewSelected: Int = 0
    @EnvironmentObject var bleScanner: BLEScanner
    @EnvironmentObject var viewModel: EnvironmentViewModel
//    @EnvironmentObject var awdlScanner: AWDLNetServiceBrowser
    @EnvironmentObject var appliedFilters: AppliedFilters
    @ObservedObject var rssiViewModel = RSSIGraphViewModel()
    
    @State var launched = false
    @State var showSettings = false
    
    let settingsPublisher = NotificationCenter.default.publisher(for: Notification.Name.App.showPreferences)
    
    let environmentScannerPublisher = NotificationCenter.default.publisher(for: Notification.Name.App.showEnvironment)
    let deviceListPublisher = NotificationCenter.default.publisher(for: Notification.Name.App.showDeviceList)
    let rssiPublisher = NotificationCenter.default.publisher(for: Notification.Name.App.showRSSI)
    let awdlPublisher = NotificationCenter.default.publisher(for: Notification.Name.App.showAWDL)
    
    var catalystView: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .center) {
                Rectangle()
                    .fill(Color("SegmentedControlBackground"))
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 50.0)
                
                Picker(selection: $currentViewSelected, label: Text("Select Mode")) {
                    Text("BLE Devices").font(.title).tag(0)
                    Text("Environment Scanner").font(.title).tag(1)
                    Text("RSSI Graph").font(.title).tag(2)
//                    Text("AWDL Scanner").font(.title).tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 550.0, height: 50.0)
                //                .background()
            }
            
            Group {
                if currentViewSelected == 1 {
                    EnvironmentScanner()
                        .environmentObject(bleScanner)
                        .environmentObject(viewModel)
                    
                }else if currentViewSelected == 2 {
                    RSSIPlotsView()
                        .environmentObject(self.rssiViewModel)
                }
                
                else if currentViewSelected == 3 {
//                    AWDLScannerView().environmentObject(awdlScanner)
                    
                }else {
                    DeviceListView().environmentObject(bleScanner).environmentObject(viewModel)
                    
                }
            }
        }.edgesIgnoringSafeArea(.top)
    }
    
    var iOSView: some View {
        TabView {
            DeviceListView().environmentObject(bleScanner).environmentObject(viewModel)
                .tabItem {
                    Image(systemName:"list.dash")
                    Text("BLE Devices")
            }
            
            EnvironmentScanner()
                .environmentObject(bleScanner).environmentObject(viewModel)
                .tabItem {
                    Image(systemName:"dot.radiowaves.left.and.right")
                    Text("Environment Scanner")
            }
            
            RSSIPlotsView()
                .environmentObject(self.rssiViewModel)
                .tabItem({
                    Image("GraphIcon")
                        .imageScale(.small)
                    Text("RSSI Graph")
                })
            
//            AWDLScannerView().environmentObject(awdlScanner)
//                .tabItem {
//                    Image(systemName:"wifi")
//                    Text("AWDL Scanner")
//            }
            
        }
    }
    
    var errorView: some View {
        Group {
            if self.bleScanner.lastError != nil {
                InfoView(importance: .error, enableSwipeDown: true, onDismissed: {
                    self.bleScanner.lastError = nil
                }) {
                    Text("Msg_Error_occurred")
                        .font(.subheadline)
                        .padding(.bottom)
                    Text(String(describing: self.bleScanner.lastError!))
                }
            }
        }
        
    }

    
    var body: some View {
        
        ZStack {
            #if targetEnvironment(macCatalyst)
            self.catalystView
            #else
            self.iOSView
            #endif
            
            if !bleScanner.connectedToReceiver {
                ConnectingView().environmentObject(self.bleScanner)
            }
            
            self.errorView
                .transition(AnyTransition.move(edge: .bottom))
                .animation(Animation.easeIn(duration: 1.0))
            
        }
        .sheet(isPresented: self.$showSettings) {
            SettingsView().environmentObject(self.bleScanner)
        }
        .onAppear {
            guard !self.launched else {return}
            self.bleScanner.scanning = true
//            self.awdlScanner.startSearching()
            self.launched = true
        }
        .onReceive(self.settingsPublisher, perform: { _ in
            self.showSettings = true
        })
        .onReceive(self.deviceListPublisher, perform: {_ in
            self.currentViewSelected = 0
        })
        .onReceive(self.environmentScannerPublisher, perform: { _ in
            self.currentViewSelected = 1
        })
        .onReceive(self.rssiPublisher, perform: { _ in
            self.currentViewSelected = 2
        })
        .onReceive(self.awdlPublisher, perform: { _ in
            self.currentViewSelected = 3
        })


        
    }
}

struct MainTabbarView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(BLEScanner())
//            .environmentObject(AWDLNetServiceBrowser())
            .environmentObject(EnvironmentViewModel())
    }
}
