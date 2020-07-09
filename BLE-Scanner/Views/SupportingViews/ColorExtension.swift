//
//  ColorExtension.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 03.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import SwiftUI

extension Color {
    static var highlight: Color {Color("Highlight")}
    static var isOn: Color {Color("isOnColor")}
    static var isOff: Color {Color("isOffColor")}
    static var isSending: Color {Color("isSendingColor")}
    static var notSending: Color {Color("notSendingColor")}
    static var segmentedControlBackground: Color {Color("SegmentedControlBackground")}
    static var buttonBackground: Color {Color("ButtonBackground")}
    static var background: Color {Color("Background")}
    
    static var lightGray: Color {Color("LightGray")}
    
    static var textColor: Color {Color("TextColor")}
    
    static func highlightColor(at index: Int) -> Color {
        let color: Color = {
            if index >= 10 {
                return Color("defHighlight")
            }
            return Color("h\(index)")
        }()
        
        
        return color
    }
}
