//
//  AppDelegate.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 02.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import UIKit
@_exported import BLETools

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        guard builder.system == UIMenuSystem.main else {return}
        
//        let showDevicesScanner = UIKeyCommand(title: "Menu_Show_devices",
//        action: #selector(showSceneForDeviceList(_:)),
//        input: "n",
//        modifierFlags: .command)
//
////        let showRadiusScanner = UIKeyCommand(title: NSLocalizedString("Menu_show_radius_scanner", comment: "Menu bar item"), action: #selector(showSceneForRadiusScanner))
//
//        let menu = UIMenu(title: "", image: nil, identifier: .file, options: .displayInline, children: [showDevicesScanner])
//
//        builder.insertChild(menu, atStartOfMenu: .file)
        
        builder.replaceChildren(ofMenu: .file) { oldChildren in
            var newChildren = oldChildren
            
            let showDevicesList = UIKeyCommand(
                title: NSLocalizedString("Menu_Show_devices", comment: "Menu bar item"),
                action: #selector(showSceneForDeviceList(_:)),
                input: "D",
                modifierFlags: .command)
            
            let showRadiusScanner = UIKeyCommand(
                title: NSLocalizedString("Menu_show_radius_scanner", comment: "Menu bar item"),
                action: #selector(showSceneForRadiusScanner(_:)),
                input: "R",
                modifierFlags: .command)
            
            newChildren.insert(showDevicesList, at: 0)
            newChildren.insert(showRadiusScanner, at: 1)
            
            return newChildren
        }
    
    }
    
    @objc func showSceneForDeviceList(_ sender: AnyObject?) {
        
    }
    
    @objc func showSceneForRadiusScanner(_ sender: AnyObject?) {
        
        let userActivity = NSUserActivity(activityType: "de.tu-darmstadt.seemoo.live-analysis")
        
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

