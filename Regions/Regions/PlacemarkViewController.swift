//
//  LocationViewController.swift
//  Regions
//
//  Created by doudou on 9/5/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class PlacemarkViewController:UITableViewController
{
	let CELL_IDENTIFIER:String = "PlacemarkCell"
	var placemark:CLPlacemark!
	
	private var list:[NSObject]!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		tableView.registerNib(UINib(nibName: "PlacemarkCell", bundle: nil), forCellReuseIdentifier: CELL_IDENTIFIER)
		
		list = []
		for (key, value) in placemark.addressDictionary
		{
			list.append(key)
		}
	}
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
		return 3
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		switch section
		{
			case 0:return "Attributes"
			case 1:return "Address Dictionary"
			default:return "Geographic"
		}
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as UITableViewCell!
		if indexPath.section == 0
		{
			switch indexPath.row
			{
				case 0:
					cell.textLabel?.text = "name"
					cell.detailTextLabel?.text = placemark.name
				case 1:
					cell.textLabel?.text = "country"
					cell.detailTextLabel?.text = placemark.country
				case 2:
					cell.textLabel?.text = "administrativeArea"
					cell.detailTextLabel?.text = placemark.administrativeArea
				case 3:
					cell.textLabel?.text = "subAdministrativeArea"
					cell.detailTextLabel?.text = placemark.subAdministrativeArea
				case 4:
					cell.textLabel?.text = "locality"
					cell.detailTextLabel?.text = placemark.locality
				case 5:
					cell.textLabel?.text = "subLocality"
					cell.detailTextLabel?.text = placemark.subLocality
				case 6:
					cell.textLabel?.text = "thoroughfare"
					cell.detailTextLabel?.text = placemark.thoroughfare
				case 7:
					cell.textLabel?.text = "subThoroughfare"
					cell.detailTextLabel?.text = placemark.subThoroughfare
				case 8:
					cell.textLabel?.text = "ISOcountryCode"
					cell.detailTextLabel?.text = placemark.ISOcountryCode
				default:
					cell.textLabel?.text = "postalCode"
					cell.detailTextLabel?.text = placemark.postalCode
			}
		}
		else
		if indexPath.section == 1
		{
			var key = list[indexPath.row]
			var value: AnyObject = placemark.addressDictionary[key]!
			
			cell.textLabel?.text = key.description
			if value is [String]
			{
				cell.detailTextLabel?.text = (value as [String]).first
			}
			else
			{
				cell.detailTextLabel?.text = (value as String)
			}
		}
		else
		{
			if indexPath.row == 0
			{
				cell.textLabel?.text = "inlandWater"
				cell.detailTextLabel?.text = placemark.inlandWater
			}
			else
			{
				cell.textLabel?.text = "ocean"
				cell.detailTextLabel?.text = placemark.ocean
			}
		}
		
		return cell
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		switch section
		{
			case 0:return 10
			case 1:return placemark.addressDictionary.count
			default:return 2
		}
	}
}
