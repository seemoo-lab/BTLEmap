//
//  MainTabbarView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 03.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import AWDLScanner
import BLETools
import AWDLScanner

struct MainView: View {
    @State var currentViewSelected: Int = 0
    @EnvironmentObject var bleScanner: BLEScanner
    @EnvironmentObject var viewModel: EnvironmentViewModel
    @EnvironmentObject var awdlScanner: AWDLNetServiceBrowser
    
    @State var launched = false

    
    var body: some View {
        
        ZStack {
            #if targetEnvironment(macCatalyst)
            
            VStack {
                ZStack(alignment: .center) {
                    Rectangle()
                        .fill(Color("SegmentedControlBackground"))
                        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 50.0)
                    
                    Picker(selection: $currentViewSelected, label: Text("Select Mode")) {
                        Text("BLE Devices").font(.title).tag(0)
                        Text("Environment Scanner").font(.title).tag(1)
                        Text("AWDL Scanner").font(.title).tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 450.0, height: 50.0)
                    //                .background()
                }
                
                Group {
                    if currentViewSelected == 1 {
                        EnvironmentScanner().environmentObject(bleScanner).environmentObject(viewModel)
                        
                    }else if currentViewSelected == 2 {
                        AWDLScannerView().environmentObject(awdlScanner)
                        
                    }else {
                        DeviceListView().environmentObject(bleScanner).environmentObject(viewModel)
                        
                    }
                }
            }.edgesIgnoringSafeArea(.top)
            

            #else
            
            TabView {
                DeviceListView().environmentObject(bleScanner).environmentObject(viewModel)
                    .tabItem {
                        Image(systemName:"list.dash")
                        Text("BLE Devices")
                }
                
                EnvironmentScanner().environmentObject(bleScanner).environmentObject(viewModel)
                    .tabItem {
                        Image(systemName:"dot.radiowaves.left.and.right")
                        Text("Environment Scanner")
                }
                
                AWDLScannerView().environmentObject(awdlScanner)
                    .tabItem {
                        Image(systemName:"wifi")
                        Text("AWDL Scanner")
                }
                
            }
            
            #endif
            
            if !bleScanner.connectedToReceiver {
                ConnectingView().environmentObject(self.bleScanner)
            }
            
        }
        .onAppear {
            guard !self.launched else {return}
            self.bleScanner.scanning = true
            self.awdlScanner.startSearching()
            self.launched = true
        }

        
    }
}

struct MainTabbarView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environmentObject(BLEScanner()).environmentObject(AWDLNetServiceBrowser()).environmentObject(EnvironmentViewModel())
    }
}
