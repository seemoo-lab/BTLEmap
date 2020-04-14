//
//  FilterSettings.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 14.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI

struct FilterSettings:View {
    @Binding var selectedManufacturers: [String]
    @Binding var minimumRSSI:Float
    @State var showManufacturerSelection = false
    @EnvironmentObject var bleScanner: BLEScanner
    @State var devicesCanTimeout = true
    
    var filterButton: some View {
        Button(action: {
            self.showManufacturerSelection.toggle()
        }, label:  {
            Image(systemName: "line.horizontal.3.decrease.circle")
                .imageScale(.large)
        })
            .popoverSheet(isPresented: self.$showManufacturerSelection, content: {
                ManfucaturerSelection(selectedManufacturers: self.$selectedManufacturers, isShown: self.$showManufacturerSelection)
            })
    }
    
    var sliderRange = Float(-100.0)...Float(0.0)
    
    
    var body: some View {
        Group {
            
            
            self.filterButton
            
            Slider(value: self.$minimumRSSI,in: self.sliderRange)
                .frame(maxWidth: 200.0)
            
            if self.minimumRSSI <= -100 {
                Text(String("Minimum RSSI -∞"))
            }else {
                Text(String(format: "Minimum RSSI %0.fdBm", Float(self.minimumRSSI)))
            }
            
            //                Slider(value: self.$minimumRSSI, in: Float(-100.0)...Float(0.0))
            ////                    .frame(maxWidth: CGFloat(200.0))
            //                if self.minimumRSSI == -Float.infinity {
            //                    Text(String("Minimum RSSI -∞"))
            //                }else {
            //                    Text(String(format: "Minimum RSSI %.0fdBm", self.minimumRSSI))
            //                }
        }
    }
}

struct FilterSettings_Previews: PreviewProvider {
    @State static var selectedManufacturers: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}
    @State static var minRSSI: Float = -100
    
    static var previews: some View {
        FilterSettings(selectedManufacturers: self.$selectedManufacturers, minimumRSSI: self.$minRSSI)
    }
}
