//
//  MenuBarHandler.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 23.04.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import UIKit

class MenuBarHandler {
    func buildMenu(with builder: UIMenuBuilder) {
        
        //Remove uneeded menus
        builder.remove(menu: .edit)
        builder.remove(menu: .format)
        builder.remove(menu: .view)
        builder.remove(menu: .help)
        
        self.buildApplicationMenu(builder: builder)
        self.buildFileMenu(builder)
    }
    
    func buildApplicationMenu(builder: UIMenuBuilder) {
        builder.replaceChildren(ofMenu: .application) { (oldchildren) -> [UIMenuElement] in
            var newChildren = oldchildren
            
            let preferences = UIKeyCommand(
                title: NSLocalizedString("XZX_Prefernces",
                comment: "Menu bar item"),
                action: #selector(AppDelegate.showPreferences(_:)),
                input: ",",
                modifierFlags: .command)
            
            newChildren.insert(preferences, at: 2)
            
            return newChildren
        }
    }
    
    func buildFileMenu(_ builder: UIMenuBuilder) {
        builder.replaceChildren(ofMenu: .file) { oldChildren in
            var newChildren = [UIMenuElement]()
            
            let createNewWindow = UIKeyCommand(
                title: NSLocalizedString("Menu_new_window", comment: "Menu bar item"),
                action: #selector(AppDelegate.newWindow(_:)),
                input: "N",
                modifierFlags: .command)
            

            let showDevicesList = UIKeyCommand(
                title: NSLocalizedString("Menu_Show_devices", comment: "Menu bar item"),
                action: #selector(AppDelegate.showSceneForDeviceList(_:)),
                input: "D",
                modifierFlags: .command)
            
            let showRadiusScanner = UIKeyCommand(
                title: NSLocalizedString("Menu_show_radius_scanner", comment: "Menu bar item"),
                action: #selector(AppDelegate.showSceneForRadiusScanner(_:)),
                input: "E",
                modifierFlags: .command)
            
            let showRSSI = UIKeyCommand(
            title: NSLocalizedString("Menu_show_RSSI", comment: "Menu bar item"),
            action: #selector(AppDelegate.showRSSIGraph(_:)),
            input: "R",
            modifierFlags: .command)
            
            let showAWDL = UIKeyCommand(
            title: NSLocalizedString("Menu_show_AWDL", comment: "Menu bar item"),
            action: #selector(AppDelegate.showAWDL(_:)),
            input: "A",
            modifierFlags: .command)
            
            newChildren.append(createNewWindow)
            newChildren.append(showDevicesList)
            newChildren.append(showRadiusScanner)
            newChildren.append(showRSSI)
            newChildren.append(showAWDL)
            
            return newChildren
        }
    }
    

    

}
