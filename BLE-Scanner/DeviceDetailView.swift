//
//  DeviceDetailView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 03.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import SwiftUI
import BLETools

struct DeviceDetailView: View {
    @ObservedObject var device: BLEDevice
    
    var body: some View {
        VStack {
            HStack {
                Text("RSSI \(device.advertisements.last!.rssi.last!.intValue) dBm")
            }
            List(self.device.advertisements) { advertisement in
                AdvertismentRow(advertisement: advertisement)
            }
        }
        .navigationBarTitle(Text(device.name ?? device.id))
        .frame(minWidth: 0, maxWidth: .infinity)
    }
}

struct AdvertismentRow: View {
    @ObservedObject var advertisement: BLEAdvertisment
    
    var body: some View {
       VStack(alignment: .leading) {
            Text(advertisement.dataAttributedString.string)
            HStack {
                //                        Text("RSSI \(advertisement.rssi.last!)")
                Text("Received \(advertisement.numberOfTimesReceived) times")
            }
        }
    }
}

struct AttributedText: UIViewRepresentable {
    var attributedString: NSAttributedString
    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        label.attributedText = self.attributedString
        return label
    }
    
    func updateUIView(_ uiView:  UILabel, context: Context) {
        uiView.attributedText = attributedString
        uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        uiView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
}
