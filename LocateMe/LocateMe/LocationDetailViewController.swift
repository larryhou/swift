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
        case Course = 3
        case Speed = 4
    }
	
	var location:CLLocation!
	
	//MARK: 列表逻辑
	override func numberOfSectionsInTableView(tableView: UITableView!) -> Int
	{
		return 5
	}
	
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
    {
		var type:SectionType = SectionType.fromRaw(section)!
		switch type
		{
			case .Accuracy:return 2
			case .Altitude:return 1
			case .Coordinate:return 2
			case .Course:return 1
			case .Speed:return 1
		}
    }
    
    override func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String!
    {
		var type:SectionType = SectionType.fromRaw(section)!
        switch type
        {
			case .Accuracy:return localizeString("Accuracy")
			case .Altitude:return localizeString("Altitude")
			case .Course:return localizeString("Course")
			case .Coordinate:return localizeString("Coordinate")
			case .Speed:return localizeString("Speed")
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
					cell.detailTextLabel.text = padding(location.coordinate.latitude) + location.localizedLatitudeString
					
				}
				else
				{
					cell.textLabel.text = localizeString("longitude")
					cell.detailTextLabel.text = padding(location.coordinate.longitude) + location.localizedLongitudeString
				}
			
			case .Accuracy:
				if indexPath.row == 0
				{
					cell.textLabel.text = localizeString("horizontal")
					cell.detailTextLabel.text = location.localizedHorizontalAccuracyString
				}
				else
				{
					cell.textLabel.text = localizeString("vertical")
					cell.detailTextLabel.text = location.localizedVerticalAccuracyString
				}
			case .Altitude:
				cell.textLabel.text = localizeString("altitude")
				cell.detailTextLabel.text = location.localizedAltitudeString
			
			case .Course:
				cell.textLabel.text = localizeString("course")
				cell.detailTextLabel.text = location.localizedCourseString
			
			case .Speed:
				cell.textLabel.text = localizeString("speed")
				cell.detailTextLabel.text = location.localizedSpeedString
		}
		
		return cell
	}
}
