//
//  DocumentPickerView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 16.03.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct DocumentPicker: UIViewControllerRepresentable {
    
    var exportURL: URL
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        
        let controller = UIDocumentPickerViewController(url: exportURL, in: .exportToService)
        controller.shouldShowFileExtensions = true
        
        
        if let userFolder = NSSearchPathForDirectoriesInDomains(.userDirectory, .userDomainMask, true).first {
            controller.directoryURL = URL(fileURLWithPath: userFolder)
        }
        
        return controller
    }
    
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    }
    
}
