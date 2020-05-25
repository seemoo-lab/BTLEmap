//
//  SceneDelegate.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 02.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import UIKit
import SwiftUI
import BLETools

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
     
    var window: UIWindow?
    let bleScanner = Model.bleScanner
    let viewModel = Model.viewModel
//    let awdlScanner = Model.awdlScanner
    let filters = AppliedFilters()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        let contentView = MainView()
            .environmentObject(bleScanner)
            .environmentObject(viewModel)
//            .environmentObject(awdlScanner)
            .environmentObject(filters)
        
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            #if targetEnvironment(macCatalyst)
            if let titlebar = windowScene.titlebar {
                titlebar.titleVisibility = .hidden
                titlebar.toolbar = nil
            }
            #endif

            
            let window = UIWindow(windowScene: windowScene)
            let vc = UIHostingController(rootView: contentView)
            
            window.rootViewController = vc
            if self.window == nil {
                self.window = window
            }
            window.largeContentTitle = "Devices"
            window.makeKeyAndVisible()
        }
    }
    
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        scene.userActivity
    }

    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    
}

