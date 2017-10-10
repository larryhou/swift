//
//  VisionPowerTests.swift
//  VisionPowerTests
//
//  Created by larryhou on 04/09/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import XCTest
@testable import VisionPower

class VisionPowerTests: XCTestCase
{
    
    override func setUp()
    {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown()
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample()
    {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample()
    {
        let layout = AlbumPreviewViewLayout()
        // This is an example of a performance test case.
        self.measure
        {
            for _ in 0...1000
            {
                layout.fitgrid(dimension:1080)
            }
            // Put the code you want to measure the time of here.
        }
    }
    
}
