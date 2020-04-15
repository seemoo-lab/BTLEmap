//
//  FilterSettings.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 14.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI

//Use as environment object
class AppliedFilters: ObservableObject {
    @Published var selectedManufacturers: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}
    @Published var minRSSI: Float = -100
    
    var manufacturerBinding: Binding<[String]>!
    var rssiBinding: Binding<Float>!
    
    init() {
        self.manufacturerBinding = Binding<[String]>.init(get: { () -> [String] in
            return self.selectedManufacturers
        },set: { (v) in
            self.selectedManufacturers = v
        })
        
        self.rssiBinding = Binding<Float>.init(get: { () -> Float in
            return self.minRSSI
        },set: { (v) in
            self.minRSSI = v
        })
    }
    
   
}

struct FilterSettings:View {
    @EnvironmentObject var appliedFilters: AppliedFilters
    @State var showManufacturerSelection = false
    @State var devicesCanTimeout = true
    
    var filterButton: some View {
        Button(action: {
            self.showManufacturerSelection.toggle()
        }, label:  {
            Image(systemName: "line.horizontal.3.decrease.circle")
                .imageScale(.large)
        })
            .popoverSheet(isPresented: self.$showManufacturerSelection, content: {
                ManfucaturerSelection(selectedManufacturers: self.appliedFilters.manufacturerBinding, isShown: self.$showManufacturerSelection)
            })
    }
    
    var sliderRange = Float(-100.0)...Float(0.0)
    
    
    var body: some View {
        Group {
            self.filterButton
            
            Slider(value: self.appliedFilters.rssiBinding, in: self.sliderRange)
                .frame(maxWidth: 200.0)
            
            if self.appliedFilters.minRSSI <= -100 {
                Text(String("Minimum RSSI -∞"))
            }else {
                Text(String(format: "Minimum RSSI %0.fdBm", Float(self.appliedFilters.minRSSI)))
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
        FilterSettings()
    }
}
