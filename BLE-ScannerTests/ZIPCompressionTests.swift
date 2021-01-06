//
//  ZIPCompressionTests.swift
//  BLE-ScannerTests
//
//  Created by Alex - SEEMOO on 12.05.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import XCTest
@testable import BTLEmap

class ZIPCompressionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCompression() {
        do {
            
            let sourceString = """
            Lorem ipsum dolor sit amet consectetur adipiscing elit mi
            nibh ornare proin blandit diam ridiculus, faucibus mus
            dui eu vehicula nam donec dictumst sed vivamus bibendum
            aliquet efficitur. Felis imperdiet sodales dictum morbi
            vivamus augue dis duis aliquet velit ullamcorper porttitor,
            lobortis dapibus hac purus aliquam natoque iaculis blandit
            montes nunc pretium.
            """.data(using: .utf8)!
            
            let compressed = try CompressionController.compress(sourceString, algorithm: .zlib)
            
            let decompressed = try CompressionController.decompress(compressed, algorithm: .zlib)
            
            XCTAssertEqual(sourceString, decompressed)
            
            let desktopURL =   FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = desktopURL.appendingPathComponent("compression-test.zip")
            try compressed.write(to: fileURL)
            
            print(fileURL)
            
            
        }catch let error {
            print(error)
            XCTFail()
        }
        
    }

}
