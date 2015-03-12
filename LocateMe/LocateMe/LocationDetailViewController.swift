//
//  LocationDetailViewController.swift
//  LocateMe
//
//  Created by larryhou on 8/20/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class LocationDetailViewController:UITableViewController
{
	private let DETAIL_CELL_IDENTIFIER:String = "LocationDetailCell"
	
    enum SectionType:Int
    {
        case Accuracy = 0
		case Coordinate = 1
        case Altitude = 2
        case Movement = 3
    }
	
	var location:CLLocation!
	
	//MARK: 列表逻辑
	override func numberOfSectionsInTableView(tableView: UITableView!) -> Int
	{
		return 4
	}
	
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
    {
		var type:SectionType = SectionType.fromRaw(section)!
		switch type
		{
			case .Accuracy:return 2
			case .Altitude:return 1
			case .Coordinate:return 2
			case .Movement:return 2
		}
    }
    
    override func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String!
    {
		var type:SectionType = SectionType.fromRaw(section)!
        switch type
        {
			case .Accuracy:return localizeString("Accuracy")
			case .Altitude:return localizeString("Altitude")
			case .Movement:return localizeString("Movement")
			case .Coordinate:return localizeString("Coordinate")
        }
    }
	
	func padding(latlong:Double)->String
	{
		var value = latlong
		
		var count = 3
		while (value > 1)
		{
			value /= 10
			count--
		}
		
		var prefix:String = ""
		while count > 0
		{
			prefix += "0"
			count--
		}
		
		return prefix
	}
	
	override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!
	{
		var cell = tableView.dequeueReusableCellWithIdentifier(DETAIL_CELL_IDENTIFIER) as UITableViewCell
		
		var type:SectionType = SectionType.fromRaw(indexPath.section)!
		switch type
		{
			case .Coordinate:
				if indexPath.row == 0
				{
					cell.textLabel.text = localizeString("latitude")
					location.coordinate.latitude
					cell.detailTextLabel.text = padding(location.coordinate.latitude) + location.getLatitudeString()
					
				}
				else
				{
					cell.textLabel.text = localizeString("longitude")
					cell.detailTextLabel.text = padding(location.coordinate.longitude) + location.getLongitudeString()
				}
			
			case .Accuracy:
				if indexPath.row == 0
				{
					cell.textLabel.text = localizeString("horizontal")
					cell.detailTextLabel.text = location.getHorizontalAccuracyString()
				}
				else
				{
					cell.textLabel.text = localizeString("vertical")
					cell.detailTextLabel.text = location.getVerticalAccuracyString()
				}
			case .Altitude:
				cell.textLabel.text = localizeString("altitude")
				cell.detailTextLabel.text = location.getAltitudeString()
			
			case .Movement:
				if indexPath.row == 0
				{
					cell.textLabel.text = localizeString("course")
					cell.detailTextLabel.text = location.getCourseString()
				}
				else
				{
					cell.textLabel.text = localizeString("speed")
					cell.detailTextLabel.text = location.getSpeedString()
				}
		}
		
		return cell
	}
}
