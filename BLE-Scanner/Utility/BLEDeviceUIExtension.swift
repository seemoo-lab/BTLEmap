//
//  BLEDeviceUIExtension.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 02.07.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import BLETools
import CoreBluetooth

extension BLEDevice {
    func imageName() -> String {
        if self.manufacturer == .seemoo {
            return "seemoo"
        }
        
        if self.advertisements.contains(where: {$0.serviceUUIDs?.contains(CBUUID(string: "FD6F")) == true}) {
            return "CovidTracing"
        }
        
        return self.deviceModel?.deviceType.string ?? BLEDeviceModel.DeviceType.other.string
    }
}
