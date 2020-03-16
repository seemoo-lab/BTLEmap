//
//  DetailWindowController.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 13.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import SwiftUI

/// A class to handle opening windows for posts when doubling clicking the entry
class DetailWindowController<RootView : View>: NSObject {
    init(rootView: RootView) {
        let hostingController = UIHostingController(rootView: rootView.frame(width: 400, height: 500))
        let window = UIWindow()
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        super.init()
    }
}
