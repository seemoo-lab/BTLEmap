//
//  NotificationNames.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 22.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation

extension Notification.Name {
    struct App {
        static var showPreferences: Notification.Name {
            return Notification.Name("showPrefs")
        }
        
        static var showDeviceList: Notification.Name {
            return Notification.Name("showDeviceList")
        }
        
        static var showEnvironment: Notification.Name {
            return Notification.Name("showEnvironment")
        }
        
        static var showRSSI: Notification.Name {
            return Notification.Name("showRSSI")
        }
        
        static var showAWDL: Notification.Name {
            return Notification.Name("showAWDL")
        }
        
        static var importingPcapFinished: Notification.Name {
            return Notification.Name("pcapimportfinished")
        }
    }
}
