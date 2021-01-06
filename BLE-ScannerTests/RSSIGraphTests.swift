//
//  RSSIGraphTests.swift
//  BLE-ScannerTests
//
//  Created by Alex - SEEMOO on 15.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import XCTest
@testable import BTLEmap
import BLETools
import SwiftUI

class RSSIGraphTests: XCTestCase {
    @State var scroll = false
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

//    func testRSSIToGraphPoint() {
//        let rssiValues = -0 ... -100
//        let id = "some-id"
//        var date = Date()
//        
//        let testPoints = [RSSIPlotsView.RSSIMultiDevicePlot.DevicePlotInfo(deviceId: id, plotColor: Color.red, rssis: rssiValues.map{
//            date += 5.0
//            return RSSIPlotsView.RSSIDate(rssi: Float($0), date: date)
//        })]
//        let height: CGFloat = 100
//        let width: CGFloat = 300
//        
//        
//        
//        let plot = RSSIPlotsView.RSSIMultiDevicePlot(plotInfo: testPoints, height: height, width: width, scroll: self.$scroll)
//        
//        testPoints.first?.rssis.forEach({ (rssiDate) in
//            let y = plot.y(for: rssiDate.rssi)
//            let x = plot.x(for: rssiDate.date)
//            
//            let expectedY = 100 + abs(rssiDate.rssi)
//            
////            XCTAssertEqual(<#T##expression1: Equatable##Equatable#>, <#T##expression2: Equatable##Equatable#>)
//        })
//    }

}
