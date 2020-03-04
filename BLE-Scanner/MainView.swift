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
    
    var deviceListView = DeviceListView()
    var environmentScanner = EnvironmentScanner()
    
    var body: some View {
        VStack {
            ZStack(alignment: .center) {
                Picker(selection: $currentViewSelected, label: Text("What is your favorite color?")) {
                    Text("Devices").font(.headline).tag(0)
                    Text("Environment Scanner").font(.headline).tag(1)
                }.pickerStyle(SegmentedPickerStyle())
            }
            
            
            
            if currentViewSelected == 1 {
                EnvironmentScanner()
            }else {
                DeviceListView()
            }
        }
        
    }
}

struct MainTabbarView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
