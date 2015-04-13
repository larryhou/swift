//
//  main.swift
//  googleQuote
//
//  Created by larryhou on 4/12/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import Foundation

var verbose = false
var zoneAdjust = false

func getQuoteRequest(ticket:String, #interval:Int, numOfDays:Int = 1, exchange:String = "HKG")->NSURLRequest
{
	let timestamp = UInt(NSDate().timeIntervalSince1970 * 1000)
	let url = "http://www.google.com/finance/getprices?q=\(ticket)&x=\(exchange)&i=\(interval)&p=\(numOfDays)d&f=d,c,v,k,o,h,l&df=cpct&auto=1&ts=\(timestamp)&ei=yW0qVam9A-f1igLUvIGQBw"
	return NSURLRequest(URL: NSURL(string: url)!)
}

func getQuoteRequest(ticket:String, #exchange:String)->NSURLRequest
{
	let timestamp = UInt(NSDate().timeIntervalSince1970 * 1000)
	let url = "http://www.google.com/finance/getprices?q=\(ticket)&x=\(exchange)&i=86400&p=40Y&f=d,c,v,k,o,h,l&df=cpct&auto=1&ts=\(timestamp)&ei=yW0qVam9A-f1igLUvIGQBw"
	return NSURLRequest(URL: NSURL(string: url)!)
}

struct QuoteKey
{
	static let DATE = "DATE"
	static let CLOSE = "CLOSE", HIGH = "HIGH", LOW = "LOW", OPEN = "OPEN"
	static let VOLUME = "VOLUME"
}

func formatQuote(text:String)->String
{
	let value = NSString(string: text).doubleValue
	return String(format: "%6.2f", value)
}

func dateOffset(date:NSDate, minuteOffset:Int)->NSDate
{
	if zoneAdjust
	{
		let interval:NSTimeInterval = date.timeIntervalSince1970 + NSTimeInterval(minuteOffset) * 60 -
			NSTimeInterval(NSTimeZone.localTimeZone().secondsFromGMT)
		return NSDate(timeIntervalSince1970: interval)
	}
	else
	{
		return date
	}
}

func parseQuote(rawlist:[String])
{
	var ready = false
	var step:Int = 0, offset:Int = 0
	
	let dateMatch = NSPredicate(format: "SELF MATCHES %@", "^a\\d{10},.*")
	let zoneMatch = NSPredicate(format: "SELF MATCHES %@", "^TIMEZONE_OFFSET=-?\\d+$")
	var cols:[String]!
	
	var formatter = NSDateFormatter()
	formatter.dateFormat = "yyyy-MM-dd,HH:mm:SS"
	
	var time = 0
	for i in 0..<rawlist.count
	{
		var line = rawlist[i]
		
		if !ready
		{
			line = line.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
			
			var params = line.componentsSeparatedByString("=")
			if verbose
			{
				println(": ".join(params))
			}
			
			switch params[0]
			{
				case "INTERVAL":
					step = NSString(string: params[1]).integerValue
					break
					
				case "DATA":
					ready = true
					break
				case "COLUMNS":
					cols = params[1].componentsSeparatedByString(",")
					break
					
				default:break
			}
		}
		else
		{
			if zoneMatch.evaluateWithObject(line)
			{
				var params = line.componentsSeparatedByString("=")
				offset = NSString(string: params[1]).integerValue
			}
			
			var components = line.componentsSeparatedByString(",")
			if line == "" || components.count < 5
			{
				continue
			}
			
			if dateMatch.evaluateWithObject(line)
			{
				var first = components.first!
				first = first.substringFromIndex(advance(first.startIndex, 1))
				time = NSString(string: first).integerValue
				components[0] = "0"
			}
			
			var item:[String:String] = [:]
			for n in 0..<components.count
			{
				item.updateValue(components[n], forKey: cols[n])
			}
			
			let index = NSString(string: item[QuoteKey.DATE]!).integerValue
			var date = NSDate(timeIntervalSince1970: NSTimeInterval(time + index * step))
			date = dateOffset(date, offset)
			
			let open = formatQuote(item[QuoteKey.OPEN]!)
			let high = formatQuote(item[QuoteKey.HIGH]!)
			let low  = formatQuote(item[QuoteKey.LOW]!)
			let close = formatQuote(item[QuoteKey.CLOSE]!)
			let volume = item[QuoteKey.VOLUME]!
			
			let msg = "\(formatter.stringFromDate(date)),\(open),\(high),\(low),\(close),\(volume)"
			println(msg)
		}
	}
	
	if verbose
	{
		println(QuoteKey.DATE + "," + QuoteKey.OPEN + "," + QuoteKey.HIGH + "," + QuoteKey.LOW + "," + QuoteKey.CLOSE + "," + QuoteKey.VOLUME)
	}
}

func fetchQuote(request:NSURLRequest)
{
	if verbose
	{
		println(request.URL!)
	}
	
	var response:NSURLResponse?
	var error:NSError?
	
	let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)
	if error == nil
	{
		let text = NSString(data: data!, encoding: NSUTF8StringEncoding)!
		let list = text.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()) as! [String]
		parseQuote(list)
	}
	else
	{
		println(error!)
	}
}

func judge(@autoclosure condition:()->Bool, message:String)
{
	if !condition()
	{
		println("ERR: " + message)
		exit(1)
	}
}

if Process.arguments.filter({$0 == "-h"}).count == 0
{
	let count = Process.arguments.filter({$0 == "-t"}).count
	judge(count >= 1, "[-t STOCK_TICKET] MUST be provided")
	judge(count == 1, "[-t STOCK_TICKET] has been set \(count) times")
	judge(Process.argc >= 3, "Unenough Parameters")
}

var interval = 60
var ticket:String = "0700"
var exchange = "HKG"
var numOfDays:Int = 1
var all = false

var skip:Bool = false
for i in 1..<Int(Process.argc)
{
	let option = Process.arguments[i]
	if skip
	{
		skip = false
		continue
	}
	
	switch option
	{
		case "-t":
			judge(Process.arguments.count > i + 1, "-t lack of parameter")
			ticket = Process.arguments[i + 1]
			skip = true
			break
		
		case "-x":
			judge(Process.arguments.count > i + 1, "-x lack of parameter")
			exchange = Process.arguments[i + 1]
			skip = true
			break
		
		case "-i":
			judge(Process.arguments.count > i + 1, "-i lack of parameter")
			interval = NSString(string: Process.arguments[i + 1]).integerValue
			skip = true
			break
		
		case "-d":
			judge(Process.arguments.count > i + 1, "-d lack of parameter")
			numOfDays = NSString(string: Process.arguments[i + 1]).integerValue
			skip = true
			break
		
		case "-v":
			verbose = true
			break
		
		case "-a":
			all = true
			break
		
		case "-z":
			zoneAdjust = true
			break
		
		case "-h":
			let msg = Process.arguments[0] + " -t STOCK_TICKET [-i QUOTE_INTERVAL_SECONDS] [-d NUM_OF_DAYS] [-x EXCHANGE_NAME] [-z TIME_ZONE_ADJUST] [-a ALL_HISTORICAL_QUOTES]"
			println(msg)
			exit(0)
			break
			
		default:
			println("Unsupported arguments: " + Process.arguments[i])
			exit(2)
	}
}

if !all
{
	fetchQuote(getQuoteRequest(ticket, interval: interval, numOfDays: numOfDays, exchange:exchange))
}
else
{
	fetchQuote(getQuoteRequest(ticket, exchange: exchange))
}
