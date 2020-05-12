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

    var menuHandler = MenuBarHandler()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //Start scanning
        Model.bleScanner.scanning = true
        
        return true
    }

    
    //MARK:- Mac Menu
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        guard builder.system == UIMenuSystem.main else {return}

        self.menuHandler.buildMenu(with: builder)
    }
    
    
    @objc func newWindow(_ sender: AnyObject?) {
        let userActivity = NSUserActivity(activityType: "de.tu-darmstadt.seemoo.new-window")
               
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil)
    }
    
    @objc func showSceneForDeviceList(_ sender: AnyObject?) {
         NotificationCenter.default.post(name: Notification.Name.App.showDeviceList, object: nil)
    }
    
    
    
    @objc func showSceneForRadiusScanner(_ sender: AnyObject?) {
        NotificationCenter.default.post(name: Notification.Name.App.showEnvironment, object: nil)
    }
    
    @objc func showRSSIGraph(_ sender: AnyObject?) {
        NotificationCenter.default.post(name: Notification.Name.App.showRSSI, object: nil)
    }
    
    @objc func showAWDL(_ sender: AnyObject?) {
        NotificationCenter.default.post(name: Notification.Name.App.showAWDL, object: nil)
    }
    
    @objc func showPreferences(_ sender: AnyObject?) {
        NotificationCenter.default.post(name: Notification.Name.App.showPreferences, object: nil)
    }
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        
        if options.userActivities.first?.activityType == "de.tu-darmstadt.seemoo.awdlService.detail" {
            return UISceneConfiguration(name: "AWDLServiceDetail Configuration", sessionRole: .windowApplication)
        }
        
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: .windowApplication)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

@discardableResult
func share( items: [Any],excludedActivityTypes: [UIActivity.ActivityType]? = nil,frame: CGRect?=nil) -> Bool {
        guard let source = UIApplication.shared.windows.first?.rootViewController else {
            return false
        }
        let vc = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        vc.excludedActivityTypes = excludedActivityTypes
        if let rect = frame {
            vc.popoverPresentationController?.sourceRect = rect
        }else {
            vc.popoverPresentationController?.sourceRect = CGRect(x: source.view.frame.maxX - 50.0, y: 150.0, width: 0, height: 0)
        }
        
        vc.popoverPresentationController?.sourceView = source.view
        source.present(vc, animated: true)
        return true
}

func export(file url: URL) {
    guard let source = UIApplication.shared.windows.first?.rootViewController else {
        return
    }

    let controller = UIDocumentPickerViewController(url: url, in: .exportToService)
    controller.shouldShowFileExtensions = true
    
    
    if let userFolder = NSSearchPathForDirectoriesInDomains(.userDirectory, .userDomainMask, true).first {
        controller.directoryURL = URL(fileURLWithPath: userFolder)
    }
    
//    controller.popoverPresentationController?.sourceRect = frame
    controller.popoverPresentationController?.sourceView = source.view
    source.present(controller, animated: true)
}
