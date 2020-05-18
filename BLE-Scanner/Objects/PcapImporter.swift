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

class PcapController: NSObject, ObservableObject, UIDocumentPickerDelegate {
    
    let bleScanner: BLEScanner = Model.bleScanner
    
    var mode: UIDocumentPickerMode
    
    var finishedCallback: ((Result<Void,Error>)->())?
    
    override init() {
        self.mode = .moveToService
        print("Initializing import controller")
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        switch mode {
        case .exportToService:
            self.finishedCallback?(.success(()))
        case .import:
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
        default:
            return
        }
        
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        //Handle like a success case
        NotificationCenter.default.post(name: Notification.Name.App.importingPcapFinished, object: self)
    }
    
    
    private func unzip(zipURL: URL) throws -> Data {
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
        
        self.mode = .import
        
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
    
    func pcapExport(_ finished: @escaping (Result<Void, Error>)->() ) {
        self.mode = .exportToService
        self.finishedCallback = finished
        //Generate PCAP data
        DispatchQueue.global(qos: .userInitiated).async {
            
            let pcapData = PcapExport.export(advertisements: self.bleScanner.advertisements)
            
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!
            let pcapURL = documentsURL.appendingPathComponent("export.pcap")
            let zipURL = documentsURL.appendingPathComponent("export.pcap.zip")
            
            do {
                //Delete file
                try? FileManager.default.removeItem(at: pcapURL)
                try? FileManager.default.removeItem(at: zipURL)
                //Write pcap to file
                try pcapData.write(to: pcapURL)
                
                //Compress pcap file
                let fileManager = FileManager.default
                try fileManager.zipItem(at: pcapURL, to: zipURL)
                
                //Delete pcap file
                try fileManager.removeItem(at: pcapURL)
                
            }catch let error {
                //TODO: Show error
                DispatchQueue.main.async {
                    finished(.failure(error))
                }
                return
            }
            
            DispatchQueue.main.async {
                finished(.success(()))
                guard let source = UIApplication.shared.windows.first?.rootViewController else {
                    return
                }
                
                let controller = UIDocumentPickerViewController(url: zipURL, in: .exportToService)
                controller.shouldShowFileExtensions = true
                controller.delegate = self
                
                if let userFolder = NSSearchPathForDirectoriesInDomains(.userDirectory, .userDomainMask, true).first {
                    controller.directoryURL = URL(fileURLWithPath: userFolder)
                }
                
                var presentationController = source
                while presentationController.presentedViewController != nil {
                    presentationController = presentationController.presentedViewController!
                }
                
                
                controller.popoverPresentationController?.sourceView = presentationController.view
                presentationController.present(controller, animated: true)
            }
        
        }
        
    }
}
