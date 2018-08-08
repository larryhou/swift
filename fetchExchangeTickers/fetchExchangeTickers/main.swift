//
//  main.swift
//  fetchExchangeTickers
//
//  Created by larryhou on 4/17/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import Foundation

var verbose = false

struct StockExchange {
	struct ExchangeInfo {
		let name: String
		let abbr: String

		func match(var value: String) -> Bool {
			value = value.lowercaseString
			return name.lowercaseString == value || abbr.lowercaseString == value
		}
	}

	static let NASDAQ = ExchangeInfo(name: "NASDAQ", abbr: "NASQ")
	static let NYSE = ExchangeInfo(name: "NYSE", abbr: "NYSE")
	static let HKG = ExchangeInfo(name: "HKG", abbr: "HK")
	static let SHA = ExchangeInfo(name: "SHA", abbr: "SS")
	static let SHE = ExchangeInfo(name: "SHE", abbr: "SZ")

	static func match(value: String) -> ExchangeInfo? {
		var list = [NASDAQ, NYSE, HKG, SHA, SHE]
		for i in 0..<list.count {
			if list[i].match(value) {
				return list[i]
			}
		}

		return nil
	}
}

func getURLRequest(ticker: String) -> NSURLRequest {
	var formatter = NSDateFormatter()
	formatter.dateFormat = "yyyy-MM-dd"

	let date = formatter.stringFromDate(NSDate()).componentsSeparatedByString("-")

	let url = "http://ichart.finance.yahoo.com/x?s=\(ticker)&d=\(date[1])&e=\(date[2])&f=\(date[0])&g=v"
	return NSURLRequest(URL: NSURL(string: url)!)
}

func parseTickerMessage(content: String) {
	var formatter = NSDateFormatter()
	formatter.dateFormat = "yyyyMMdd"

	let list = content.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
	for i in 1..<list.count {
		var cols = list[i].stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil).componentsSeparatedByString(",")
		if cols.count < 3 {
			continue
		}

		formatter.dateFormat = "yyyyMMdd"
		let date = formatter.dateFromString(cols[1])!
		formatter.dateFormat = "yyyy-MM-dd"

		var msg = formatter.stringFromDate(date)
		msg += String(format: ", %8s", NSString(string: cols[2]).cStringUsingEncoding(NSASCIIStringEncoding))
		msg += ", " + cols[0]
		println(msg)

	}
}

func checkTickers(list: [String]) {
	for i in 0..<list.count {
		var response: NSURLResponse?, error: NSError?
		let data = NSURLConnection.sendSynchronousRequest(getURLRequest(list[i]), returningResponse: &response, error: &error)
		if error == nil && (response as! NSHTTPURLResponse).statusCode == 200 {
			println(list[i])
			if verbose {
				let content = NSString(data: data!, encoding: NSUTF8StringEncoding)!
				parseTickerMessage(content as String)
			}
		} else {
			if verbose {
				println(response == nil ? error! : response!)
			}
		}
	}
}

func fetchHKGTickers() {
	var list: [String] = []
	for i in 1...9999 {
		list.append(String(format: "%04d.\(StockExchange.HKG.abbr)", i))
	}
	checkTickers(list)
}

func fetchSHATickers() {
	var list: [String] = []
	var traits = ["600", "601", "603", "700", "730"]
	for n in 0..<traits.count {
		for i in 1...999 {
			list.append(traits[n] + String(format: "%03d.\(StockExchange.SHA.abbr)", i))
		}
	}

	checkTickers(list)
}

func fetchSHETickers() {
	var list: [String] = []
	var traits = ["000", "300", "002", "080"]
	for n in 0..<traits.count {
		for i in 1...999 {
			list.append(traits[n] + String(format: "%03d.\(StockExchange.SHE.abbr)", i))
		}
	}

	checkTickers(list)
}

func fetchNYSETickers() {
	println("NYSE: UNIMPLEMENTED")
}

func fetchNASDAQTickers() {
	println("NASDAQ: UNIMPLEMENTED")
}

func judge(@autoclosure condition:() -> Bool, message: String) {
	if !condition() {
		println("ERR: " + message)
		exit(1)
	}
}

if Process.arguments.filter({$0 == "-h"}).count == 0
	&& Process.arguments.filter({$0 == "-t"}).count == 0 {
	let count = Process.arguments.filter({$0 == "-x"}).count
	judge(count >= 1, "[-x EXCHANGE_NAME] MUST be provided")
	judge(count == 1, "[-x EXCHANGE_NAME] has been set \(count) times")
	judge(Process.argc >= 3, "Unenough Parameters")
}

var exchange = StockExchange.HKG
var ticker: String?

var skip: Bool = false
for i in 1..<Int(Process.argc) {
	let option = Process.arguments[i]
	if skip {
		skip = false
		continue
	}

	switch option {
		case "-x":
			judge(Process.arguments.count > i + 1, "-x lack of parameter")

			let data = StockExchange.match(Process.arguments[i + 1])
			if data != nil {
				exchange = data!
			}

			skip = true
			break

		case "-t":
			judge(Process.arguments.count > i + 1, "-t lack of parameter")
			ticker = Process.arguments[i + 1]
			skip = true
			break

		case "-v":
			verbose = true
			break

		case "-h":
			let msg = Process.arguments[0] + " -x EXCHANGE_NAME -t STOCK_TICKER"
			println(msg)
			exit(0)
			break

		default:
			println("Unsupported arguments: " + Process.arguments[i])
			exit(2)
	}
}

if ticker != nil {
	verbose = true
	checkTickers([ticker!])
} else {
	switch exchange.name {
		case StockExchange.HKG.name:
			fetchHKGTickers()
			break

		case StockExchange.SHE.name:
			fetchSHETickers()
			break

		case StockExchange.SHA.name:
			fetchSHATickers()
			break

		case StockExchange.NYSE.name:
			fetchNYSETickers()
			break

		case StockExchange.NASDAQ.name:
			fetchNASDAQTickers()
			break

		default:break
	}
}
