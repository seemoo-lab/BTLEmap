//
//  BLEScanner_SwiftUI.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 03.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import BLETools

class BLEScanner_SwiftUI: ObservableObject {
    @Published var devices: [AppleBLEDevice] = []
    @Published var advertisements: [AppleBLEAdvertisment] = []
    @Published var scanning = false {
        didSet {
            self.bleScanner.scanning = self.scanning
        }
    }
    
    private var bleScanner: BLEScanner = BLEScanner()
    
    init() {
        bleScanner.delegate = self
    }
    
}

extension BLEScanner_SwiftUI: BLEScannerDelegate {
    func scanner(_ scanner: BLEScanner, didDiscoverNewDevice device: AppleBLEDevice) {
        self.devices = Array(scanner.devices.values)
    }
    
    func scanner(_ scanner: BLEScanner, didReceiveNewAdvertisement advertisement: AppleBLEAdvertisment, forDevice device: AppleBLEDevice) {
        self.advertisements.append(advertisement)
    }
}


