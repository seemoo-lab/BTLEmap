//
//  ModelSceneDelegate.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 13.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation

// 1
import SwiftUI

// 2
class ModelSceneDelegate: UIResponder, UIWindowSceneDelegate {
  // 3
  var window: UIWindow?

  // 4
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let windowScene = scene as? UIWindowScene {
      // 5
      let window = UIWindow(windowScene: windowScene)
        
        
        
        if let activity = connectionOptions.userActivities.first,
            activity.activityType == "de.tu-darmstadt.seemoo.awdlService.detail",
            let serviceName  = activity.userInfo?["awdlServiceName"] as? String,
            let service = Model.awdlScanner.foundServices.first(where: {$0.name == serviceName}) {
            
            // 6
            window.rootViewController = UIHostingController(
                rootView: AWDLServiceDetailView(service: service)
            )
        }
      
      // 7
      self.window = window
      // 8
      window.makeKeyAndVisible()
    }
  }
}
