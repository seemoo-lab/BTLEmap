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
    }
}
