//
//  FilterSettings.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 14.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import BLETools

//Use as environment object
/// Applied filters contain all user set filters to reduce the amount of advertisements received.
class AppliedFilters: ObservableObject {
    @Published var selectedManufacturers: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}
    @Published var minRSSI: Float = -100
    
    @Published var filterText: String = ""
    
    var manufacturerBinding: Binding<[String]>!
    var rssiBinding: Binding<Float>!
    var filterTextBinding: Binding<String>!
    
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
        
        self.filterTextBinding = Binding<String>.init(get: { () -> String in
            return self.filterText
        }, set: { (s) in
            self.filterText = s
        })
    }
    
}

/// An extension that allows filtering a collection of BLEDevices by using the Applied Filters class
extension Collection where Element == BLEDevice  {
    func filter(with filters: AppliedFilters) -> [BLEDevice] {
        var filtered = self.filter {filters.selectedManufacturers.contains($0.manufacturer.rawValue.capitalized)}
        
        filtered = filtered.filter {
            filters.minRSSI <= -100 ? true : $0.lastRSSI >= filters.minRSSI
        }
        
        if !filters.filterText.isEmpty,
            let filterData = filters.filterText.hexadecimal {
            
            filtered = filtered.filter {
                $0.advertisements.contains {$0.manufacturerData?.range(of: filterData) != nil}
            }
        }
        
        return filtered
    }
}

struct FilterSettings:View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject var appliedFilters: AppliedFilters
    @State var showManufacturerSelection = false
    @State var devicesCanTimeout = true
    
    
    var filterButton: some View {
        Button(action: {
            self.showManufacturerSelection.toggle()
        }, label:  {
            if sizeClass == .compact {
                Image(systemName: "line.horizontal.3.decrease.circle")
                .imageScale(.large)
            }else {
                Group {
                    Text("Btn_filter_manufacturers")
                    Image(systemName: "line.horizontal.3.decrease.circle")
                    .imageScale(.large)
                }
            }
            
        })
            .popoverSheet(isPresented: self.$showManufacturerSelection, content: {
                ManfucaturerSelection(filters: self.appliedFilters)
            })
    }
    
    var sliderRange = Float(-100.0)...Float(0.0)
    
    var simpleFilters: some View {
        Group {
            self.filterButton
                .padding([.leading, .trailing])
            
            Slider(value: self.appliedFilters.rssiBinding, in: self.sliderRange)
                .frame(minWidth: 100, maxWidth: 200.0)
            
            if self.appliedFilters.minRSSI <= -100 {
                Text(String("Min RSSI -∞"))
            }else {
                Text(String(format: "Min RSSI %0.fdBm", Float(self.appliedFilters.minRSSI)))
            }
            
            
        }
    }
    
    var textFilters: some View {
        HStack {
            Button(action: {
                //
            }, label: {
                Text("Data")
            })
                .padding(7)
                .background(RoundedRectangle(cornerRadius: 5.0, style: .continuous)
                    .fill(Color.lightGray))
            
            TextField("Filter by data (hex encoded)", text: self.appliedFilters.filterTextBinding)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .font(.system(.body, design: .monospaced))
        }
        .keyboardResponsive()
//        .padding(.trailing)
    }
    
    var body: some View {
        VStack {
            HStack {
                self.textFilters
                if self.sizeClass == UserInterfaceSizeClass.regular {
                    self.simpleFilters
                }
            }
            if self.sizeClass == UserInterfaceSizeClass.compact {
                self.simpleFilters
            }
        }
        .padding()
    }
}

struct FilterSettings_Previews: PreviewProvider {
    @State static var selectedManufacturers: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}
    @State static var minRSSI: Float = -100
    
    
    static var previews: some View {
        Group {
            HStack {
                FilterSettings()
            }
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro"))
            
            HStack {
                FilterSettings()
            }
            .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (4th generation)"))
        }.environmentObject(AppliedFilters())
    }
}
