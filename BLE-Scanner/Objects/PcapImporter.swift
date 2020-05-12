//
//  PcapImporter.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 12.05.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import UIKit
import BLETools
import MobileCoreServices
import ZIPFoundation

class PcapImportController: NSObject, ObservableObject, UIDocumentPickerDelegate {
    
    let bleScanner: BLEScanner = Model.bleScanner
    
    override init() {
        print("Initializing import controller")
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        //Read the external document
        guard let fileURL = urls.first else {return}
        
        //Read the file
        do {
            let data: Data
            
            if fileURL.pathExtension == "zip" {
                data = try self.unzip(zipURL: fileURL)
            }else {
                data = try Data(contentsOf: fileURL)
            }
            
            //Import the pcap data
            bleScanner.importPcap(from: data) { (result) in
                switch result {
                case .success(_):
                    NotificationCenter.default.post(name: Notification.Name.App.importingPcapFinished, object: self)
                    
                case .failure(let pcapError):
                    NotificationCenter.default.post(name: Notification.Name.App.importingPcapFinished, object: self, userInfo: ["error": pcapError])
                    
                }
            }
        }catch let error {
            NotificationCenter.default.post(name: Notification.Name.App.importingPcapFinished, object: self, userInfo: ["error": error])
        }
        
    }
    
    func unzip(zipURL: URL) throws -> Data {
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!
        let destinationURL = documentURL.appendingPathComponent("unzip")
            
        try? FileManager.default.removeItem(at: destinationURL)
        try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: false, attributes: nil)
        try FileManager.default.unzipItem(at: zipURL, to: destinationURL)
        
        //Files
        let files = try FileManager.default.contentsOfDirectory(at: destinationURL, includingPropertiesForKeys: nil, options: .includesDirectoriesPostOrder)
        
        if let pcapURL = files.first {
            let pcapData = try Data(contentsOf: pcapURL)
            return pcapData
        }
        
        
        throw NSError(domain: "ZIP Failed", code: -1, userInfo: ["message": "Failed"])
        
    }
    
    func pcapImport() {
        guard let source = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        
        let controller = UIDocumentPickerViewController(documentTypes: [kUTTypeData as String], in: .import)
        controller.shouldShowFileExtensions = true
        controller.delegate = self
        
        
        var presentationController = source
        while presentationController.presentedViewController != nil {
            presentationController = presentationController.presentedViewController!
        }
        
        
        controller.popoverPresentationController?.sourceView = presentationController.view
        presentationController.present(controller, animated: true)
    }
}
