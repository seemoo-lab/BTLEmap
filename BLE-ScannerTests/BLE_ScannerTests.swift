//
//  BLE_ScannerTests.swift
//  BLE-ScannerTests
//
//  Created by Alex - SEEMOO on 02.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import XCTest
@testable import BLE_Scanner
import BLETools

class BLE_ScannerTests: XCTestCase, BLEScannerDelegate {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testScanningForDevices() throws {
        let expect = expectation(description: "BLE Scanner")
        let scanner = BLEScanner(delegate: self)
        scanner.scanning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 60.0)
    }
    
    func scanner(_ scanner: BLEScanner, didReceiveNewAdvertisement advertisement: AppleBLEAdvertisment, forDevice device: AppleBLEDevice) {
        print("Received advertisement")
        print(advertisement)
    }
    
    func scanner(_ scanner: BLEScanner, didDiscoverNewDevice device: AppleBLEDevice) {
        print("Discovered device")
        print(device)
    }


}
