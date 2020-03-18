//
//  Model.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 13.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import BLETools
import AWDLScanner

/// Stores static singleton instances for environment objects
struct Model {
    static let bleScanner = BLEScanner(devicesCanTimeout: UserDefaults.standard.timeoutDevices, timeoutInterval: UserDefaults.standard.timeoutInterval, filterDuplicates: UserDefaults.standard.filterDuplicates)
    static let viewModel = EnvironmentViewModel()
    static let awdlScanner = AWDLNetServiceBrowser()
}
