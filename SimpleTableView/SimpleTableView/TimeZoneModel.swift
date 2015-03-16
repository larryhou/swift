//
//  TimeZoneModel.swift
//  SimpleTableView
//
//  Created by larryhou on 3/13/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import Foundation

struct TimeZoneInfo
{
	let zone:NSTimeZone
	
	let name:String
	let formattedString:String?
	
	init(name:String)
	{
		self.name = name
		self.zone = NSTimeZone(name: name)!
		self.formattedString = format(self.zone)
	}
	
	private func format(data:NSTimeZone)->String
	{
		let offset = data.secondsFromGMT
		
		let hours = abs(offset) / 3600
		let minutes = abs(offset % 3600) / 60
		
		var result = NSString(format: "%02d:%02d ", hours, minutes) as String
		result = "UTC" + (offset >= 0 ? "+" : "-") + result + name
		return result
	}
}

class TimeZoneModel
{
	class var model:TimeZoneModel
	{
		struct Proxy
		{
			static let model:TimeZoneModel = TimeZoneModel()
		}
		
		return Proxy.model
	}
	
	private var _keys:[String]
	var keys:[String]
	{
		return _keys
	}
	
	private var _dict:[String:[TimeZoneInfo]]
	var dict:[String:[TimeZoneInfo]]
	{
		return _dict
	}
	
	private var _list:[TimeZoneInfo]
	var list:[TimeZoneInfo]
	{
		return _list
	}
	
	init()
	{
		_dict = [:]
		_keys = []
		_list = []
		
		setupTimeZones()
	}
	
	private func setupTimeZones()
	{
		let names = NSTimeZone.knownTimeZoneNames() as [String]
		for i in 0..<names.count
		{
			let zone = TimeZoneInfo(name: names[i])
			let key = zone.name.substringToIndex(advance(zone.name.startIndex, 1))
			if _dict[key] == nil
			{
				_dict[key] = [TimeZoneInfo]()
				_keys.append(key)
			}
			
			_dict[key]?.append(zone)
			_list.append(zone)
		}
		
		for (key, _) in _dict
		{
			_dict[key]?.sort()
			{
				$0.name.localizedStandardCompare($1.name) == NSComparisonResult.OrderedAscending
			}
		}
		
		_keys.sort(){$0.localizedStandardCompare($1) == NSComparisonResult.OrderedAscending}
		_list.sort()
		{
			if $0.zone.secondsFromGMT != $1.zone.secondsFromGMT
			{
				return $0.zone.secondsFromGMT < $1.zone.secondsFromGMT
			}
			
			return $0.name.localizedStandardCompare($1.name) == NSComparisonResult.OrderedAscending
		}
	}
}