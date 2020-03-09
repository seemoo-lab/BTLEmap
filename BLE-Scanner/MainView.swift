//
//  MainTabbarView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 03.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @State var currentViewSelected: Int = 0
    @EnvironmentObject var bleScanner: BLEScanner
    @EnvironmentObject var viewModel: EnvironmentViewModel
    
    var body: some View {
        
        VStack {
            #if targetEnvironment(macCatalyst)
            ZStack(alignment: .center) {
                Rectangle()
                    .fill(Color("SegmentedControlBackground"))
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 50.0)
                
                Picker(selection: $currentViewSelected, label: Text("Select Mode")) {
                    Text("Devices").font(.title).tag(0)
                    Text("Environment Scanner").font(.headline).tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 350.0, height: 50.0)
//                .background()
            }
            
            if currentViewSelected == 1 {
                EnvironmentScanner().environmentObject(bleScanner).environmentObject(viewModel)
            }else {
                DeviceListView().environmentObject(bleScanner).environmentObject(viewModel)
            }
            #else
            
            TabView {
                DeviceListView().environmentObject(bleScanner).environmentObject(viewModel)
                    .tabItem {
                        Image(systemName:"list.dash")
                        Text("Devices")
                }
                
                EnvironmentScanner().environmentObject(bleScanner).environmentObject(viewModel)
                    .tabItem {
                        Image(systemName:"dot.radiowaves.left.and.right")
                        Text("Environment Scanner")
                }
                
            }
            
            #endif
        }
        
    }
}

struct MainTabbarView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
