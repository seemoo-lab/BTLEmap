//
//  RSSI_AngleCalculation_Tests.swift
//  BLE-ScannerTests
//
//  Created by Alex - SEEMOO on 09.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import BLETools
import XCTest

@testable import BLE_Scanner

class RSSI_AngleCalculation_Tests: XCTestCase {

    var measurement1: [RSSIAngle] {
        let fileURL = Bundle(for: self.classForCoder).url(
            forResource: "rssi_measurement_1", withExtension: "csv")!
        let csvString = String(data: try! Data(contentsOf: fileURL), encoding: .utf8)!
        return RSSI_AngleCalculation_Tests.parseCSVToRSSIs(csvString)

    }

    var measurement2: [RSSIAngle] {
        let fileURL = Bundle(for: self.classForCoder).url(
            forResource: "rssi_measurement_2", withExtension: "csv")!
        let csvString = String(data: try! Data(contentsOf: fileURL), encoding: .utf8)!
        return RSSI_AngleCalculation_Tests.parseCSVToRSSIs(csvString)
    }

    var measurement3: [RSSIAngle] {
        let fileURL = Bundle(for: self.classForCoder).url(
            forResource: "rssi_measurement_3", withExtension: "csv")!
        let csvString = String(data: try! Data(contentsOf: fileURL), encoding: .utf8)!
        return RSSI_AngleCalculation_Tests.parseCSVToRSSIs(csvString)
    }
    
    var measurement4: [RSSIAngle] {
        let fileURL = Bundle(for: self.classForCoder).url(
            forResource: "rssi_measurement_4", withExtension: "csv")!
        let csvString = String(data: try! Data(contentsOf: fileURL), encoding: .utf8)!
        return RSSI_AngleCalculation_Tests.parseCSVToRSSIs(csvString)
    }

    static func parseCSVToRSSIs(_ csv: String) -> [RSSIAngle] {
        var rssis = [RSSIAngle]()
        csv.split(separator: "\n").dropFirst().enumerated().forEach { (idx, line) in
            let entries = line.split(separator: ";").map({ $0.trimmingCharacters(in: .whitespaces) }
            )
            rssis.append(RSSIAngle(idx: idx, value: Float(entries[2])!, angle: Double(entries[1])!))
        }

        return rssis
    }

    func testAngleMeasurement1() {
        let rssis = self.measurement1
        print("Calculating angle with \(rssis.count) measurements")
        let average = AngleCalculation.calculateAverageRSSI(with: rssis)
        let angleNormal = AngleCalculation.calculateAngle(with: rssis, and: average)

        let angleOpposite = AngleCalculation.calculateAngleOpposite(with: rssis, and: average)

        //        let actualAngle =

        let angleRange = -.pi...Double.pi
        XCTAssert(angleRange.contains(angleNormal))
        XCTAssert(angleRange.contains(angleOpposite))
        
    }

    //Expected angle is known
    func testMeasurement3() {
        let expectedAngle = -0.4369782409475728

        let rssis = self.measurement3
        print("Calculating angle with \(rssis.count) measurements")
        let average = AngleCalculation.calculateAverageRSSI(with: rssis)
        let angleNormal = AngleCalculation.calculateAngle(with: rssis, and: average)

        let angleOpposite = AngleCalculation.calculateAngleOpposite(with: rssis, and: average)

        //        let actualAngle =

        let angleRange = -.pi...Double.pi
        XCTAssert(angleRange.contains(angleNormal))
        XCTAssert(angleRange.contains(angleOpposite))

        //Detect which algorithm is better
        XCTAssertEqual(angleOpposite, expectedAngle, accuracy: 5.0 * .pi / 180.0)
        XCTAssertEqual(angleNormal, expectedAngle, accuracy: 5.0 * .pi / 180.0)

    }
    
    func testMeasurement4() {
        let expectedAngle = 1.201191306175151

               let rssis = self.measurement4
               print("Calculating angle with \(rssis.count) measurements")
               let average = AngleCalculation.calculateAverageRSSI(with: rssis)
               let angleNormal = AngleCalculation.calculateAngle(with: rssis, and: average)

               let angleOpposite = AngleCalculation.calculateAngleOpposite(with: rssis, and: average)

               //        let actualAngle =

               let angleRange = -.pi...Double.pi
               XCTAssert(angleRange.contains(angleNormal))
               XCTAssert(angleRange.contains(angleOpposite))

               //Detect which algorithm is better
               XCTAssertEqual(angleOpposite, expectedAngle, accuracy: 5.0 * .pi / 180.0)
               XCTAssertEqual(angleNormal, expectedAngle, accuracy: 5.0 * .pi / 180.0)

    }

}
