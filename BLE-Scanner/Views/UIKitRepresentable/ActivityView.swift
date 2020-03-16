//
//  ActivityView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 13.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import UIKit
import SwiftUI

class UIActivityViewControllerHost: UIViewController {
    var items: [Any] = []
    var completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler? = nil

    override func viewDidAppear(_ animated: Bool) {
        share()
    }

    func share() {
        // set up activity view controller
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        activityViewController.completionWithItemsHandler = completionWithItemsHandler
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash

        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    var items: [Any]
    @Binding var showing: Bool

    func makeUIViewController(context: Context) -> UIActivityViewControllerHost {
        // Create the host and setup the conditions for destroying it
        let result = UIActivityViewControllerHost()

        result.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            // To indicate to the hosting view this should be "dismissed"
            self.showing = false
        }

        return result
    }

    func updateUIViewController(_ uiViewController: UIActivityViewControllerHost, context: Context) {
        // Update the text in the hosting controller
        uiViewController.items = items
    }

}


struct ActivityViewController: UIViewControllerRepresentable {

    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
//        controller.popoverPresentationController?.barButtonItem = context.environment.

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {
    }

}
