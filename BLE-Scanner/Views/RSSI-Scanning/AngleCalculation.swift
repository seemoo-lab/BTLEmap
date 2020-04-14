//
//  AngleCalculation.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 09.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import BLETools
import Foundation

struct AngleCalculation {
    /// Recorded device
    let device: BLEDevice
    /// Average RSSI value
    let averageRSSI: Float
    /// Value between -pi and +pi  / -180 deg and +180 deg (in radians)
    let calculatedAngle: Float

    init(rssis: [RSSIAngle], device: BLEDevice) {
        self.device = device
        let average = AngleCalculation.calculateAverageRSSI(with: rssis)
        self.averageRSSI = average
        self.calculatedAngle = Float(
            AngleCalculation.calculateAngleOpposite(with: rssis, and: average))
    }
    
    //Use a sliding window of 5 degrees and detect the window with the lowest average
    static let windowSize: Double = 10 * .pi / 180
    static let windowStepSize: Double = 0.5 * .pi / 180

    static func calculateAverageRSSI(with rssis: [RSSIAngle]) -> Float {
        return rssis.reduce(Float(0)) { (res, entry) -> Float in
            res + entry.value
        } / Float(rssis.count)
    }

    /// This function calculates the angle with the highest RSSI to use the opposite angle as the acutal device angle.
    /// - Parameters:
    ///   - rssis: Array of recorded RSSIS with angle
    ///   - average: Average of all RSSIs
    /// - Returns: The at which the device is plaaced. In the range from -pi to +pi
    static func calculateAngleOpposite(with rssis: [RSSIAngle], and average: Float) -> Double {
        //Remember: RSSIs are negative values. Therefore Higher values = closer, better reception

        //We calculate the angle at which the user was standing with the back to the device to get the opposite of the actual angle

        //Get all values below the average.
        //        let belowAverage = rssis.filter({$0.value < average})

        //Sort RSSIs by angle
        let sortedRSSIs = rssis.sorted { (r1, r2) -> Bool in
            r1.angle < r2.angle
        }

        
        /// Angle where the sliding window starts
        var windowStart: Double = 0 - .pi

        /// Window where the RSSI values indicates that the device is close
        var closestWindow: (start: Double, average: Float) = (0.0, .infinity)

        while windowStart < .pi {
            let curentWindowEnd = windowStart + windowSize

            let currentWindowRange = windowStart...curentWindowEnd
            //Get the RSSIs in the window
            let currentWindow = sortedRSSIs.filter({
                if curentWindowEnd > .pi {
                    //Window extends to other side of circle
                    return $0.angle > windowStart || $0.angle < (curentWindowEnd - 2 * .pi)
                }

                return currentWindowRange.contains($0.angle)
            })

            if currentWindow.count == 0 {
                windowStart += windowStepSize
                print("No values for \(currentWindowRange)")
                continue
            }

            //Calculate the average
            let windowAverage =
                currentWindow.reduce(Float(0), { $0 + $1.value }) / Float(currentWindow.count)

            print("Average: \(windowAverage)\t \(currentWindowRange) \t \(currentWindow.count)")

            // Higher values = closer
            if closestWindow.average > windowAverage {
                //New closest window discovered
                closestWindow = (windowStart, windowAverage)
            }

            windowStart += windowStepSize
        }

        let oppositeAngle = closestWindow.start + windowSize/2

        if oppositeAngle > 0 {
            return oppositeAngle - .pi
        }

        return oppositeAngle + .pi
    }

    /// - Returns: The at which the device is plaaced. In the range from -pi to +pi
    static func calculateAngle(with rssis: [RSSIAngle], and average: Float) -> Double {
        //Remember: RSSIs are negative values. Therefore Higher values = closer, better reception

        //Use the average to detect clusters of values that are below the average

        //Get all values above the average.
        //        let belowAverage = rssis.filter({$0.value > average})

        //Sort RSSIs by angle
        let sortedRSSIs = rssis.sorted { (r1, r2) -> Bool in
            r1.angle < r2.angle
        }

        /// Angle where the sliding window starts
        var windowStart: Double = -.pi

        /// Window where the RSSI values indicates that the device is close
        var closestWindow: (start: Double, average: Float) = (0.0, -.infinity)

        while windowStart < .pi {
            let curentWindowEnd = windowStart + windowSize

            let currentWindowRange = windowStart...curentWindowEnd
            //Get the RSSIs in the window
            let currentWindow = sortedRSSIs.filter({
                if curentWindowEnd > .pi {
                    //Window extends to other side of circle
                    return $0.angle > windowStart || $0.angle < (curentWindowEnd - 2 * .pi)
                }

                return currentWindowRange.contains($0.angle)
            })

            if currentWindow.count == 0 {
                windowStart += windowStepSize
                print("No values for \(currentWindowRange)")
                continue
            }

            //Calculate the average
            let windowAverage =
                currentWindow.reduce(Float(0), { $0 + $1.value }) / Float(currentWindow.count)

            print("Average: \(windowAverage)\t \(currentWindowRange) \t \(currentWindow.count)")

            // Higher values = closer
            if closestWindow.average < windowAverage {
                //New closest window discovered
                closestWindow = (windowStart, windowAverage)
            }

            windowStart += windowStepSize
        }

        return closestWindow.start + windowSize/2
    }
}

struct RSSIAngle: Identifiable {
    var id: Int
    var value: Float
    var angle: Double

    init(idx: Int, value: Float, angle: Double) {
        self.id = idx
        self.value = value
        self.angle = angle
    }
}
