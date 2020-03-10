//
//  AdvertisementTypeFilterView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 10.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import BLETools
import SwiftUI

struct AdvertisementTypeFilterView: View {
    var allAdvertisementTypes = BLEAdvertisment.AppleAdvertisementType.allCases.sorted(by: {$0.description < $1.description})
    
    @Binding var selectedAdvertisementTypes: [BLEAdvertisment.AppleAdvertisementType]
    @Binding var isShown: Bool
    
    var body: some View {
        NavigationView {
            List(self.allAdvertisementTypes, id: \.self) { advertisementType in
                Button(action: {
                    if let idx = self.selectedAdvertisementTypes.firstIndex(of: advertisementType) {
                        self.selectedAdvertisementTypes.remove(at: idx)
                    }else {
                        self.selectedAdvertisementTypes.append(advertisementType)
                    }
                }) {
                    
                    HStack {
                        Text(advertisementType.description)
                        Spacer()
                        Image(systemName: self.selectedAdvertisementTypes.contains(advertisementType) ? "checkmark.circle.fill" : "circle")
                    }
                }.buttonStyle(DefaultButtonStyle())
            }
            .navigationBarTitle(Text("Title_advertisement_selection"), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {self.isShown = false}, label: {Text("Btn_Dismiss")}))
            .navigationBarItems(leading: HStack {
                if self.selectedAdvertisementTypes.count == self.allAdvertisementTypes.count {
                    Button(action: {
                        self.selectedAdvertisementTypes = []
                    }, label: {Text("Btn_deselect_all")})
                }else {
                    Button(action: {
                        self.selectedAdvertisementTypes = self.allAdvertisementTypes
                    }, label: {Text("Btn_select_all")})
                }
            })
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
