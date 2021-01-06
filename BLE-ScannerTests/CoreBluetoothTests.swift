//
//  CoreBluetoothTests.swift
//  BLE-ScannerTests
//
//  Created by Alex - SEEMOO on 02.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import XCTest
import CoreBluetooth
@testable import BTLEmap

class CoreBluetoothTests: XCTestCase {
    let cManager: CBCentralManager = CBCentralManager()
    var startScanning = false
    
    override func setUp() {
        cManager.delegate = self
    }
    
    func testScan() {
        if cManager.state == .poweredOn {
            cManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            print("started scanning")
        }else {
            startScanning = true
        }
        
        let expect = expectation(description: "BLE Scanner")
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 60.0)
    }
}

extension CoreBluetoothTests: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && startScanning  {
            cManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
                       print("started scanning")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered peripheral")
        print("Advertisement data: \(advertisementData)")
    }
    
}
