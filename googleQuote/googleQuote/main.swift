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

var eventTimeFormatter = DateFormatter()
eventTimeFormatter.dateFormat = "yyyy-MM-dd"

func sendSynchronousRequest(_ url:String, response rspt:AutoreleasingUnsafeMutablePointer<HTTPURLResponse?>?, error erpt:AutoreleasingUnsafeMutablePointer<Error?>?)->Data?
{
    var data:Data?
    if let url = URL(string: url)
    {
        let loop = CFRunLoopGetCurrent()
        URLSession(configuration: .ephemeral).dataTask(with: url)
        { (body, response, error) in
            
            data = body
            rspt?.pointee = response as! HTTPURLResponse?
            erpt?.pointee = error
            CFRunLoopStop(loop)
            }.resume()
        
        CFRunLoopRun()
    }
    else
    {
        erpt?.pointee = NSError(domain: "HTTPSession", code: -1, userInfo: nil)
    }
    
    return data
}

func getQuoteQuery(_ ticket:String, interval:Int, numOfDays:Int = 1, exchange:String = "HKG")->String
{
	let timestamp = UInt(Date().timeIntervalSince1970 * 1000)
	let url = "http://www.google.com/finance/getprices?q=\(ticket)&x=\(exchange)&i=\(interval)&p=\(numOfDays)d&f=d,c,v,k,o,h,l&df=cpct&auto=1&ts=\(timestamp)&ei=yW0qVam9A-f1igLUvIGQBw"
	return url
}

func getQuoteQuery(_ ticket:String, exchange:String)->String
{
	let timestamp = UInt(Date().timeIntervalSince1970 * 1000)
	let url = "http://www.google.com/finance/getprices?q=\(ticket)&x=\(exchange)&i=86400&p=40Y&f=d,c,v,k,o,h,l&df=cpct&auto=1&ts=\(timestamp)&ei=yW0qVam9A-f1igLUvIGQBw"
	return url
}

struct QuoteKey
{
	static let DATE = "DATE"
	static let CLOSE = "CLOSE", HIGH = "HIGH", LOW = "LOW", OPEN = "OPEN"
	static let VOLUME = "VOLUME"
}

struct StockExchange
{
	struct ExchangeInfo
	{
		let name:String
		let abbr:String
	}
	
	static let NASDAQ = ExchangeInfo(name: "NASDAQ", abbr: "NASQ")
	static let NYSE = ExchangeInfo(name: "NYSE", abbr: "NYSE")
	static let HKG = ExchangeInfo(name: "HKG", abbr: "HK")
	static let SHA = ExchangeInfo(name: "SHA", abbr: "SS")
	static let SHE = ExchangeInfo(name: "SHE", abbr: "SZ")
}

func formatQuote(_ text:String)->String
{
	let value = NSString(string: text).doubleValue
	return String(format: "%6.2f", value)
}

func dateOffset(_ date:Date, minuteOffset:Int)->Date
{
	if zoneAdjust
	{
		let interval:TimeInterval = date.timeIntervalSince1970 + TimeInterval(minuteOffset) * 60 -
			TimeInterval(NSTimeZone.local.secondsFromGMT())
		return Date(timeIntervalSince1970: interval)
	}
	else
	{
		return date
	}
}

enum CooprActionType:String
{
	case SPLIT = "SPLIT"
	case DIVIDEND = "DIVIDEND"
}

struct CoorpAction:CustomStringConvertible
{
	let date:Date
	let type:CooprActionType
	var value:Double
	
	var description:String
	{
		let vstr = String(format:"%.6f", value)
		return "\(eventTimeFormatter.string(from: date))|\(vstr)|\(type.rawValue)"
	}
}

func createActionMap(_ list:[CoorpAction]?, formatter:DateFormatter)->[String:CoorpAction]
{
	var map:[String:CoorpAction] = [:]
	if list == nil
	{
		return map
	}
	
	for i in 0..<list!.count
	{
		let key = formatter.string(from: list![i].date)
		map[key] = list![i]
	}
	
	return map
}

func parseQuote(_ rawlist:[String])
{
	var ready = false
	var step:Int = 0, offset:Int = 0
	
	let dateMatch = NSPredicate(format: "SELF MATCHES %@", "^a\\d{8,},.*")
	let zoneMatch = NSPredicate(format: "SELF MATCHES %@", "^TIMEZONE_OFFSET=-?\\d+$")
	var cols:[String]!
	
	let formatter = DateFormatter()
	formatter.dateFormat = "yyyy-MM-dd"
	
	var dmap:[String:CoorpAction] = createActionMap(dividends, formatter: formatter)
	var splitAction:CoorpAction!
	
	formatter.dateFormat = "yyyy-MM-dd,HH:mm:SS"
	print("date,time,open,high,low,close,volume,split,dividend")
	
	var time = 0
	for i in 0..<rawlist.count
	{
		var line = rawlist[i]
		
		if !ready
		{
			line = line.removingPercentEncoding!
			
			var params = line.components(separatedBy: "=")
			if verbose
			{
				print(params.joined(separator: ": "))
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
					cols = params[1].components(separatedBy: ",")
					break
					
				default:break
			}
		}
		else
		{
			if zoneMatch.evaluate(with: line)
			{
				var params = line.components(separatedBy: "=")
				offset = NSString(string: params[1]).integerValue
			}
			
			var components = line.components(separatedBy: ",")
			if line == "" || components.count < 5
			{
				continue
			}
			
			if dateMatch.evaluate(with: line)
			{
				var first = components.first!
				first = first.substring(from: first.index(first.startIndex, offsetBy: 1))
                
				time = NSString(string: first).integerValue
				components[0] = "0"
			}
			
			var item:[String:String] = [:]
			for n in 0..<components.count
			{
				item.updateValue(components[n], forKey: cols[n])
			}
			
			let index = NSString(string: item[QuoteKey.DATE]!).integerValue
			var date = Date(timeIntervalSince1970: TimeInterval(time + index * step))
			date = dateOffset(date, minuteOffset: offset)
			let dateString = formatter.string(from: date)
			
			let open = formatQuote(item[QuoteKey.OPEN]!)
			let high = formatQuote(item[QuoteKey.HIGH]!)
			let low  = formatQuote(item[QuoteKey.LOW]!)
			let close = formatQuote(item[QuoteKey.CLOSE]!)
			let volume = NSString(string: item[QuoteKey.VOLUME]!).doubleValue
			
			var msg = "\(dateString),\(open),\(high),\(low),\(close)," + String(format:"%10.0f", volume)
			if splits != nil && splits.count > 0
			{
				while splits.count > 0
				{
					if (splitAction == nil || date.timeIntervalSince(splitAction.date) >= 0)
						&& date.timeIntervalSince(splits[0].date) < 0
					{
						splitAction = splits.first!
					}
					else
					{
						break
					}
					
					splits.remove(at: 0)
				}

			}
			else
			{
				if splitAction != nil && date.timeIntervalSince(splitAction.date) >= 0
				{
					splitAction = nil
				}
			}
			
			msg += "," + String(format:"%.6f", splitAction != nil ? splitAction.value : 1.0)
			
			var dividend = 0.0
			let key = dateString.components(separatedBy: ",").first!
			if dmap[key] != nil
			{
				dividend = dmap[key]!.value
			}
			msg += "," + String(format:"%.6f", dividend)
			print(msg)
		}
	}
	
	if verbose
	{
		print(QuoteKey.DATE + "," + QuoteKey.OPEN + "," + QuoteKey.HIGH + "," + QuoteKey.LOW + "," + QuoteKey.CLOSE + "," + QuoteKey.VOLUME + "," + CooprActionType.SPLIT.rawValue + "," + CooprActionType.DIVIDEND.rawValue)
	}
}

var splits, dividends:[CoorpAction]!
func fetchCooprActions(_ ticket:String, exchange:String)
{
	var coorpActions:[CoorpAction]!
	
	var suffix:String
	switch exchange
	{
		case StockExchange.SHA.name:
			suffix = StockExchange.SHA.abbr
		
		case StockExchange.SHE.name:
			suffix = StockExchange.SHE.abbr
		
		case StockExchange.HKG.name:
			suffix = StockExchange.HKG.abbr
		
		default:
			suffix = ""
	}
	
	if suffix != ""
	{
		suffix = ".\(suffix)"
	}
	
	let formatter = DateFormatter()
	formatter.dateFormat = "MM-dd-yyyy"
	
	var date = formatter.string(from: Date()).components(separatedBy: "-")
	let url = "http://ichart.finance.yahoo.com/x?s=\(ticket)\(suffix)&d=\(date[0])&e=\(date[1])&f=\(date[2])&g=v"
	if verbose
	{
		print(url)
	}
	
	formatter.dateFormat = "yyyyMMdd"
	
    var error:Error?
	var response:HTTPURLResponse?
	let data = sendSynchronousRequest(url, response: &response, error: &error)
	if error == nil && response!.statusCode == 200
	{
		coorpActions = []
		let list = String(bytes: data!, encoding: String.Encoding.utf8)!.components(separatedBy: .newlines)
		for i in 1..<list.count
		{
			let line = list[i].replacingOccurrences(of: " ", with: "", options: .forcedOrdering, range: nil)
			let cols = line.components(separatedBy: ", ")
			if cols.count < 3
			{
				continue
			}
			
			let type = CooprActionType(rawValue: cols[0])
			let date = formatter.date(from: cols[1])
			
			let value:Double
			let digits = cols[2].components(separatedBy: ":").map({NSString(string:$0).doubleValue})
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
			print(response == nil ? error! : response!)
		}
	}
	
	if coorpActions != nil
	{
		coorpActions = coorpActions.sorted(by: {$0.date.timeIntervalSince1970 < $1.date.timeIntervalSince1970})
		
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
			print(dividends)
			print(splits)
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

func fetchQuote(_ url:String)
{
	if verbose
	{
		print(url)
	}
	
	var response:HTTPURLResponse?, error:Error?
	let data = sendSynchronousRequest(url, response: &response, error: &error)
	if error == nil && response!.statusCode == 200
	{
		let text = String(bytes: data!, encoding: String.Encoding.utf8)!
		let list = text.components(separatedBy: .newlines)
		
		parseQuote(list)
		
	}
	else
	{
		if verbose
		{
			print(response == nil ? error! : response!)
		}
	}
}

func judge(_ condition:@autoclosure ()->Bool, message:String)
{
	if !condition()
	{
		print("ERR: " + message)
		exit(1)
	}
}

if CommandLine.arguments.filter({$0 == "-h"}).count == 0
{
	let count = CommandLine.arguments.filter({$0 == "-t"}).count
	judge(count >= 1, message: "[-t STOCK_TICKET] MUST be provided")
	judge(count == 1, message: "[-t STOCK_TICKET] has been set \(count) times")
	judge(CommandLine.argc >= 3, message: "Unenough Parameters")
}

var interval = 60
var ticket:String = "0700"
var exchange = "HKG"
var numOfDays:Int = 1
var all = false

var skip:Bool = false
for i in 1..<Int(CommandLine.argc)
{
	let option = CommandLine.arguments[i]
	if skip
	{
		skip = false
		continue
	}
	
	switch option
	{
		case "-t":
			judge(CommandLine.arguments.count > i + 1, message: "-t lack of parameter")
			ticket = CommandLine.arguments[i + 1]
			skip = true
			break
		
		case "-x":
			judge(CommandLine.arguments.count > i + 1, message: "-x lack of parameter")
			exchange = CommandLine.arguments[i + 1]
			skip = true
			break
		
		case "-i":
			judge(CommandLine.arguments.count > i + 1, message: "-i lack of parameter")
			interval = NSString(string: CommandLine.arguments[i + 1]).integerValue
			skip = true
			break
		
		case "-d":
			judge(CommandLine.arguments.count > i + 1, message: "-d lack of parameter")
			numOfDays = NSString(string: CommandLine.arguments[i + 1]).integerValue
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
			let msg = CommandLine.arguments[0] + " -t STOCK_TICKET [-i QUOTE_INTERVAL_SECONDS] [-d NUM_OF_DAYS] [-x EXCHANGE_NAME] [-z TIME_ZONE_ADJUST] [-a ALL_HISTORICAL_QUOTES]"
			print(msg)
			exit(0)
			break
			
		default:
			print("Unsupported arguments: " + CommandLine.arguments[i])
			exit(2)
	}
}

fetchCooprActions(ticket, exchange: exchange)

if !all
{
	fetchQuote(getQuoteQuery(ticket, interval: interval, numOfDays: numOfDays, exchange:exchange))
}
else
{
	fetchQuote(getQuoteQuery(ticket, exchange: exchange))
}
