//
//  ManfucaturerSelection.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 06.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import SwiftUI
import BLETools

struct ManfucaturerSelection: View {
    @Environment(\.presentationMode) var presentation
    
    var allManufacturers: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}.sorted()
    @ObservedObject var filters: AppliedFilters
//
//    @State var selectedManufacturers: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}.sorted()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Show devices which send advertisement using the company id for: ")
                    .foregroundColor(.gray)
                    .padding([.top])
                Divider()
                List(self.allManufacturers, id: \.self) { manufacturerString in
                    Button(action: {
                        if let idx = self.filters.selectedManufacturers.firstIndex(of: manufacturerString) {
                            self.filters.selectedManufacturers.remove(at: idx)
                        }else {
                            self.filters.selectedManufacturers.append(manufacturerString)
                        }
                    }) {
                        HStack {
                            Text(manufacturerString)
                            Spacer()
                            Image(systemName: self.filters.selectedManufacturers.contains(manufacturerString) ? "checkmark.circle.fill" : "circle")
                        }
                    }.buttonStyle(DefaultButtonStyle())
                }
            }
            .navigationBarTitle(Text("Title_manufacturer_selection"), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {self.presentation.wrappedValue.dismiss()}, label: {Text("Btn_Dismiss")}))
            .navigationBarItems(leading:
                Button(action: {
                    if self.filters.selectedManufacturers.count == self.allManufacturers.count {
                        self.filters.selectedManufacturers = []
                    }else {
                        self.filters.selectedManufacturers = self.allManufacturers
                    }
                    
                }, label: {
                    if self.filters.selectedManufacturers.count == self.allManufacturers.count {
                        Image(systemName: "minus.circle.fill")
                    }else {
                        Image(systemName: "plus.circle.fill")
                    }
                })
                    .imageScale(.large)
                    .padding()
            )
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
        

    }
    
}

struct ManfucaturerSelection_Previews: PreviewProvider {
    @State static var selected: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}
    @State static var isShown = true
    
    static var previews: some View {
        ManfucaturerSelection(filters: AppliedFilters())
    }
}
