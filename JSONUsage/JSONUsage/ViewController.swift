//
//  ViewController.swift
//  JSONUsage
//
//  Created by larryhou on 4/11/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()

        guard let url = Bundle.main.url(forResource: "0700", withExtension: "json"),
            let data = try? Data(contentsOf: url) else {
                print("JSON file not found")
                return
        }

        do {
            let jsonData = try JSONDecoder().decode(JSONData.self, from: data)
            print(jsonData)
        } catch {
            print(error.localizedDescription)
        }
	}
}

struct JSONData: Codable {
    struct Data: Codable {
        struct Indicators: Codable {
            struct Quote: Codable {
                let close: [Double?]
                let high: [Double?]
                let low: [Double?]
                let open: [Double?]
                let volume: [Double?]
            }
            let quote: [Quote]
        }
        struct Meta: Codable {
            struct TradingPeriod: Codable {
                let end: Int
                let gmtoffset: Int
                let start: Int
                let timezone: String
            }
            struct CurrentTradingPeriod: Codable {
                let post: TradingPeriod
                let pre: TradingPeriod
                let regular: TradingPeriod
            }
            let currency: String
            let currentTradingPeriod: CurrentTradingPeriod
            let dataGranularity: String
            let exchangeName: String
            let gmtoffset: Int
            let instrumentType: String
            let previousClose: Double
            let scale: Int
            let symbol: String
            let timezone: String
            let tradingPeriods: [[TradingPeriod]]
        }
        let indicators: Indicators
        let meta: Meta
        let timestamp: [Int]
    }
    let data: Data
    let debug: String
    let isLegacy: Bool
    let isValidRange: Bool
}
