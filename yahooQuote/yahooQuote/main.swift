//
//  main.swift
//  yahooQuote
//
//  Created by larryhou on 4/16/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import Foundation

var verbose = false

var eventTimeFormatter = NSDateFormatter()
eventTimeFormatter.dateFormat = "yyyy-MM-dd"

enum CooprActionType:String
{
	case SPLIT = "SPLIT"
	case DIVIDEND = "DIVIDEND"
}

struct CoorpAction:Printable
{
	let date:NSDate
	let type:CooprActionType
	var value:Double
	
	var description:String
	{
		let vstr = String(format:"%.6f", value)
		return "\(eventTimeFormatter.stringFromDate(date))|\(vstr)|\(type.rawValue)"
	}
}

func getQuoteRequest(ticket:String)->NSURLRequest
{
	var formatter = NSDateFormatter()
	formatter.dateFormat = "MM-dd-yyyy"
	
	var date = formatter.stringFromDate(NSDate()).componentsSeparatedByString("-")
	
	let url = "http://real-chart.finance.yahoo.com/table.csv?s=\(ticket)&d=\(date[0])&e=\(date[1])&f=\(date[2])&g=d&ignore=.csv"
	return NSURLRequest(URL: NSURL(string: url)!)
}

func getCoorpActionRequest(ticket:String)->NSURLRequest
{
	var formatter = NSDateFormatter()
	formatter.dateFormat = "MM-dd-yyyy"
	
	var date = formatter.stringFromDate(NSDate()).componentsSeparatedByString("-")
	let url = "http://ichart.finance.yahoo.com/x?s=\(ticket)&d=\(date[0])&e=\(date[1])&f=\(date[2])&g=v"
	
	return NSURLRequest(URL: NSURL(string: url)!)
}

var splits, dividends:[CoorpAction]!
func fetchCooprActions(request:NSURLRequest)
{
	if verbose
	{
		println(request.URL!)
	}
	
	var coorpActions:[CoorpAction]!
	
	var formatter = NSDateFormatter()
	formatter.dateFormat = "yyyyMMdd"
	
	var response:NSURLResponse?, error:NSError?
	let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)
	if error == nil && (response as! NSHTTPURLResponse).statusCode == 200
	{
		coorpActions = []
		let list = (NSString(data: data!, encoding: NSUTF8StringEncoding) as! String).componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
		for i in 1..<list.count
		{
			let line = list[i].stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.ForcedOrderingSearch, range: nil)
			let cols = line.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: ", "))
			if cols.count < 3
			{
				continue
			}
			
			let type = CooprActionType(rawValue: cols[0])
			let date = formatter.dateFromString(cols[1])
			
			let value:Double
			let digits = cols[2].componentsSeparatedByString(":").map({NSString(string:$0).doubleValue})
			if type == CooprActionType.SPLIT
			{
				value = digits[0] / digits[1]
			}
			else
			{
				value = digits[0]
			}
			
			if type != nil && date != nil
			{
				coorpActions.append(CoorpAction(date: date!, type: type!, value: value))
			}
		}
		
		if coorpActions.count == 0
		{
			coorpActions = nil
		}
	}
	else
	{
		coorpActions = nil
		if verbose
		{
			println(response == nil ? error! : response!)
		}
	}
	
	if coorpActions != nil
	{
		coorpActions.sort({$0.date.timeIntervalSince1970 < $1.date.timeIntervalSince1970})
		
		var values:[Double] = []
		for i in 0..<coorpActions.count
		{
			if coorpActions[i].type == CooprActionType.SPLIT
			{
				splits = splits ?? []
				splits.append(coorpActions[i])
				values.append(coorpActions[i].value)
			}
			else
			if coorpActions[i].type == CooprActionType.DIVIDEND
			{
				dividends = dividends ?? []
				dividends.append(coorpActions[i])
			}
		}
		
		if verbose
		{
			println(dividends)
			println(splits)
		}
		
		if splits != nil
		{
			for i in 0..<splits.count
			{
				var multiple = values[i]
				for j in (i + 1)..<splits.count
				{
					multiple *= values[j]
				}
				
				splits[i].value = multiple
			}
		}
	}
	else
	{
		dividends = nil
		splits = nil
	}
}

func createActionMap(list:[CoorpAction]?, #formatter:NSDateFormatter)->[String:CoorpAction]
{
	var map:[String:CoorpAction] = [:]
	if list == nil
	{
		return map
	}
	
	for i in 0..<list!.count
	{
		let key = formatter.stringFromDate(list![i].date)
		map[key] = list![i]
	}
	
	return map
}

func formatQuote(text:String)->String
{
	let value = NSString(string: text).doubleValue
	return String(format: "%6.2f", value)
}

func parseQuote(data:[String])
{
	var formatter = NSDateFormatter()
	formatter.dateFormat = "yyyy-MM-dd"
	
	var dmap = createActionMap(dividends, formatter: formatter)
	var splitAction:CoorpAction!
	
	println("date,open,high,low,close,volume,split,dividend,adjclose")
	
	for i in 0..<data.count
	{
		let cols = data[i].componentsSeparatedByString(",")
		if cols.count < 7
		{
			continue
		}
		
		let date = formatter.dateFromString(cols[0])!
		let open = formatQuote(cols[1])
		let high = formatQuote(cols[2])
		let low  = formatQuote(cols[3])
		let close = formatQuote(cols[4])
		let volume = NSString(string: cols[5]).doubleValue
		let adjclose = formatQuote(cols[6])
		
		var msg = "\(cols[0]),\(open),\(high),\(low),\(close)," + String(format:"%10.0f", volume)
		if splits != nil && splits.count > 0
		{
			while splits.count > 0
			{
				if (splitAction == nil || date.timeIntervalSinceDate(splitAction.date) >= 0)
					&& date.timeIntervalSinceDate(splits[0].date) < 0
				{
					splitAction = splits.first!
				}
				else
				{
					break
				}
				
				splits.removeAtIndex(0)
			}
			
		}
		else
		{
			if splitAction != nil && date.timeIntervalSinceDate(splitAction.date) >= 0
			{
				splitAction = nil
			}
		}
		
		msg += "," + String(format:"%.6f", splitAction != nil ? splitAction.value : 1.0)
		
		var dividend = 0.0, key = cols[0]
		if dmap[key] != nil
		{
			dividend = dmap[key]!.value
		}
		
		msg += "," + String(format:"%.6f", dividend)
		msg += ",\(adjclose)"
		println(msg)
	}
}

func fetchQuote(request:NSURLRequest)
{
	if verbose
	{
		println(request.URL!)
	}
	
	var response:NSURLResponse?, error:NSError?
	let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)
	if error == nil && (response as! NSHTTPURLResponse).statusCode == 200
	{
		let text = NSString(data: data!, encoding: NSUTF8StringEncoding)!
		var list = text.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()) as! [String]
		
		list.removeAtIndex(0)
		parseQuote(list.reverse())
	}
	else
	{
		if verbose
		{
			println(response == nil ? error! : response!)
		}
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

var ticket:String = "0700"

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
		
		case "-v":
			verbose = true
			break
		
		case "-h":
			let msg = Process.arguments[0] + " -t STOCK_TICKET"
			println(msg)
			exit(0)
			break
			
		default:
			println("Unsupported arguments: " + Process.arguments[i])
			exit(2)
	}
}

fetchCooprActions(getCoorpActionRequest(ticket))
fetchQuote(getQuoteRequest(ticket))

