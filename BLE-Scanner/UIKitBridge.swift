//
//  UIKitBridge.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 12.05.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation

class UIKitBridge: NSObject {
    static let shared = UIKitBridge()
    private override init() {}
    
    private var pcapImporter: PcapController?
    
    func importPcapFile() {
        if pcapImporter == nil {
            pcapImporter = PcapController()
        }
        
        pcapImporter?.pcapImport()
    }
    
    func exportPcapFile(_ finished: @escaping (Result<Void, Error>)->()) {
        if pcapImporter == nil {
            pcapImporter = PcapController()
        }
        
        pcapImporter?.pcapExport(finished)
    }
}
