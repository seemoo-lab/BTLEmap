//
//  CompressionController.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 12.05.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Compression

struct CompressionController {
    
    static func compress(_ sourceData: Data, algorithm: Algorithm) throws -> Data {
        let pageSize = 128
        var compressedData = Data()
         
        
        let outputFilter = try OutputFilter(.compress, using: algorithm, writingTo: { (data) in
            if let data = data {
                compressedData.append(data)
            }
        })
        
        var index = sourceData.startIndex
        let bufferSize = sourceData.count
        
        while true {
            let rangeLength = min(pageSize, bufferSize - index)
            
            let subdata = sourceData.subdata(in: index..<(index + rangeLength))
            index += rangeLength
            
            try outputFilter.write(subdata)
            
            if rangeLength == 0 {
                break
            }
        }
        
        return compressedData
    }
    
    static func decompress(_ compressedData: Data, algorithm: Algorithm) throws -> Data {
        var decompressedData = Data()
        
        let pageSize = 128
        var index = 0
        let bufferSize = compressedData.count
        
        let inputFilter = try InputFilter(.decompress, using: algorithm, bufferCapacity: bufferSize, readingFrom: { (length) -> Data? in
            let rangeLength = min(length, bufferSize - index)
            let subdata = compressedData.subdata(in: index..<index + rangeLength)
            index += rangeLength
            
            return subdata
        })
        
        while let page = try inputFilter.readData(ofLength: pageSize) {
            decompressedData.append(page)
        }
        
        return decompressedData
    }
}
