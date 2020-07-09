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
    @Binding var selectedManufacturers: [String]
//
//    @State var selectedManufacturers: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}.sorted()
    
    var contentList: some View {
        VStack {
            Text("Show devices which send advertisement using the company id for: ")
                .foregroundColor(.gray)
                .padding([.top,.trailing,.leading])
            Divider()
            ScrollView {
                ForEach(self.allManufacturers, id: \.self) { manufacturerString in
                    //            List(self.allManufacturers, id: \.self) { manufacturerString in
                    VStack {
                        HStack {
                            Text(manufacturerString)
                            Spacer()
                            Image(systemName: self.selectedManufacturers.contains(manufacturerString) ? "checkmark.circle.fill" : "circle")
                        }
                        Divider()
                    }
                    .padding([.leading, .trailing])
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let idx = self.selectedManufacturers.firstIndex(of: manufacturerString) {
                            self.selectedManufacturers.remove(at: idx)
                        }else {
                            self.selectedManufacturers.append(manufacturerString)
                        }
                        print("Selected manufacturers changed: \(self.selectedManufacturers)")
                    }
                }
            }
        }
        .frame(minWidth: 0,maxWidth: .infinity)
    }
    
    var navigationView: some View {
        NavigationView {
            self.contentList
            .navigationBarTitle(Text("Title_manufacturer_selection"), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {self.presentation.wrappedValue.dismiss()}, label: {Text("Btn_Dismiss")}))
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
    
    var body: some View {

        VStack {
            HStack {
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
                
                Spacer()
                
                Text("Title_manufacturer_selection")
                
                Spacer()
                
                Button(action: {self.presentation.wrappedValue.dismiss()}, label: {Text("Btn_Dismiss").padding()})
            }
            
            self.contentList
        }
        
    }
    
}

struct ManfucaturerSelection_Previews: PreviewProvider {
    @State static var selected: [String] = BLEManufacturer.allCases.map{$0.rawValue.capitalized}
    @State static var isShown = true
    
    
    static var previews: some View {
        ManfucaturerSelection(selectedManufacturers: $selected)
    }
}
