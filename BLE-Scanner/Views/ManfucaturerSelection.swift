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
    
    var allManufacturers: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}.sorted()
    @Binding var selectedManufacturers: [String]
    @Binding var isShown: Bool
    
    var body: some View {
        NavigationView {
            List(self.allManufacturers, id: \.self) { manufacturerString in
                Button(action: {
                    if let idx = self.selectedManufacturers.firstIndex(of: manufacturerString) {
                        self.selectedManufacturers.remove(at: idx)
                    }else {
                        self.selectedManufacturers.append(manufacturerString)
                    }
                }) {
                    HStack {
                        Text(manufacturerString)
                        Spacer()
                        Image(systemName: self.selectedManufacturers.contains(manufacturerString) ? "checkmark.circle.fill" : "circle")
                    }
                }.buttonStyle(DefaultButtonStyle())
            }
            .navigationBarTitle(Text("Title_manufacturer_selection"), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {self.isShown = false}, label: {Text("Btn_Dismiss")}))
            .navigationBarItems(leading:
                Button(action: {
                    if self.selectedManufacturers.count == self.allManufacturers.count {
                        self.selectedManufacturers = []
                    }else {
                        self.selectedManufacturers = self.allManufacturers
                    }
                    
                }, label: {
                    if self.selectedManufacturers.count == self.allManufacturers.count {
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
        ManfucaturerSelection(selectedManufacturers: $selected, isShown: $isShown)
    }
}
