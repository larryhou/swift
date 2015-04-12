//
//  main.swift
//  fetchQuote
//
//  Created by larryhou on 4/11/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import Foundation

var ticket:String = "0700.HK"
var zone:String = "+0800"

var related:NSDate?
var verbose = false

var automated = false

var dateFormatter = NSDateFormatter()
dateFormatter.dateFormat = "YYYY-MM-dd Z"

var timeFormatter = NSDateFormatter()
timeFormatter.dateFormat = "YYYY-MM-dd,HH:mm:ss Z"

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
		
		case "-d":
			judge(Process.arguments.count > i + 1, "-d lack of parameter")
			related = dateFormatter.dateFromString(Process.arguments[i + 1] + " \(zone)")
			judge(related != nil, "Unsupported date format:\(Process.arguments[i + 1]), e.g.2015-04-09")
			skip = true
			break
		
		case "-z":
			judge(Process.arguments.count > i + 1, "-z lack of parameter")
			zone = Process.arguments[i + 1]
			let regex = NSPredicate(format: "SELF MATCHES %@", "[+-]\\d{4}")
			judge(regex.evaluateWithObject(zone), "Unsupported time zone format:\(zone), e.g. +0800")
			skip = true
			break
		
		case "-v":
			verbose = true
			break
		
		case "-a":
			automated = true
			break
		
		case "-h":
			let msg = Process.arguments[0] + " -t STOCK_TICKET [-z TIME_ZONE] [-d DATE]"
			println(msg)
			exit(0)
			break
		
		default:
			println("Unsupported arguments: " + Process.arguments[i])
			exit(2)
	}
}

func getQuotesURL(var date:NSDate?)->NSURL
{
	if date == nil
	{
		date = NSDate()
	}
	
	let text = dateFormatter.stringFromDate(date!).componentsSeparatedByString(" ").first!
	date = timeFormatter.dateFromString("\(text),06:00:00 \(zone)")
	
	let refer = timeFormatter.dateFromString("\(text),20:00:00 \(zone)")!
	
	let s = UInt(date!.timeIntervalSince1970)
	let e = UInt(refer.timeIntervalSince1970)
	
	let url = "http://finance.yahoo.com/_td_charts_api/resource/charts;comparisonTickers=;events=div%7Csplit%7Cearn;gmtz=8;indicators=quote;period1=\(s);period2=\(e);queryString=%7B%22s%22%3A%22\(ticket)%2BInteractive%22%7D;range=1d;rangeSelected=undefined;ticker=\(ticket);useMock=false?crumb=a6xbm2fVIlt"
	
	return NSURL(string: url)!
}

class QuoteSpliter:Printable
{
	let date:NSDate
	let ratios:[Int]
	
	init(date:NSDate, ratios:[Int])
	{
		self.date = date
		self.ratios = ratios
	}
	
	var description:String
	{
		return dateFormatter.stringFromDate(date) + ", " + "/".join(ratios.map({"\($0)"}))
	}
}

func formatQuote(value:AnyObject, format:String = "%6.2f")->String
{
	return String(format:format, value as! Double)
}

func fetchQuoteOn(date:NSDate?)
{
	let url = getQuotesURL(date)
	if verbose
	{
		println(url)
	}

	var response:NSURLResponse?
	var error:NSError?
	
	var spliters:[QuoteSpliter] = []
	
	let data = NSURLConnection.sendSynchronousRequest(NSURLRequest(URL: url), returningResponse: &response, error: &error)
	if data != nil
	{
		error = nil
		var result: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: &error)
		if error == nil
		{
			let json = result as! NSDictionary
			let map = json.valueForKeyPath("data.events.splits") as? [String:[String:AnyObject]]
			if map != nil
			{
				for (key, item) in map!
				{
					let time = NSString(string: key).integerValue
					let date = NSDate(timeIntervalSince1970: NSTimeInterval(time))
					let ratios = (item["splitRatio"] as! String).componentsSeparatedByString("/").map({$0.toInt()!})
					
					spliters.append(QuoteSpliter(date: date, ratios: ratios))
				}
			}
			
			let quotes = (json.valueForKeyPath("data.indicators.quote") as! [[String:[AnyObject]]]).first!
			let stamps = json.valueForKeyPath("data.timestamp") as! [UInt]
			
			let OPEN = "open",HIGH = "high",LOW = "low",CLOSE = "close"
			let VOLUME = "volume"
			
			var list:[String] = []
			for i in 0..<stamps.count
			{
				var item:[String] = []
				var date = NSDate(timeIntervalSince1970: NSTimeInterval(stamps[i]))
				if quotes[OPEN]![i] is NSNull
				{
					continue
				}
				
				item.append(timeFormatter.stringFromDate(date).componentsSeparatedByString(" ").first!)
				item.append(formatQuote(quotes[OPEN]![i]))
				item.append(formatQuote(quotes[HIGH]![i]))
				item.append(formatQuote(quotes[LOW ]![i]))
				item.append(formatQuote(quotes[CLOSE]![i]))
				item.append("\(quotes[VOLUME]![i])")
				list.append(",".join(item))
			}
			
			if spliters.count > 0
			{
				println(spliters)
			}
			
			println("\n".join(list))
		}
		else
		{
			if verbose
			{
				println(NSString(data: data!, encoding: NSUTF8StringEncoding)!)
			}
		}
	}
	else
	{
		if verbose
		{
			if response != nil
			{
				println(response!)
			}
			
			println(error!)
		}
		
		exit(202)
	}
}

if !automated
{
	fetchQuoteOn(related)
}
else
{
	let DAY:NSTimeInterval = 24 * 3600
	related = NSDate(timeIntervalSince1970: NSDate().timeIntervalSince1970 + DAY)
	for i in 0...50
	{
		fetchQuoteOn(NSDate(timeIntervalSince1970: related!.timeIntervalSince1970 - NSTimeInterval(i) * DAY))
	}
}

