//
//  LocateViewController.swift
//  LocateMe
//
//  Created by doudou on 8/17/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

enum CellIdentifier:String
{
    case Status = "StatusCell"
    case Measurement = "MeasurementCell"
}

enum LocationUpdateStatus:String
{
	case Updating = "Updating"
	case Tracking = "Tracking"
	case TimedOut = "Timed Out"
	case Acquired = "Acquired Location"
	case Error = "Error"
}

class LocateViewController:UITableViewController, SetupSettingReceiver, CLLocationManagerDelegate
{
    enum SectionType:Int
    {
        case LocateStatus = 0
        case BestMeasurement = 1
        case Measurements = 2
    }
    
    private var setting:LocateSettingInfo!
    private var dateFormatter:NSDateFormatter!
	
	private var bestMeasurement:CLLocation!
	private var measurements:[CLLocation]!
	
	private var locationManager:CLLocationManager!
	private var timer:NSTimer!
	
	private var status:LocationUpdateStatus!
    
    func setupSetting(setting: LocateSettingInfo)
    {
        self.setting = setting
    }
    
    override func viewDidLoad()
    {
        dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = localizeString("DateFormat")
		
		measurements = []
		
		locationManager = CLLocationManager()
		locationManager.delegate = self
    }
    
    override func viewWillAppear(animated: Bool)
    {
        println(setting)
		
		locationManager.desiredAccuracy = setting.accuracy
		locationManager.startUpdatingLocation()
		
		var delay:NSTimeInterval = NSTimeInterval(setting.sliderValue)
		timer = NSTimer.scheduledTimerWithTimeInterval(delay,
			target: self, selector: "updateTimedOut",
			userInfo: nil, repeats: false)
		
// FIXME: 无法使用带参数的selector，否则报错： [NSCFTimer copyWithZone:]: unrecognized selector sent to instance
//			timer = NSTimer.scheduledTimerWithTimeInterval(delay,
//			target: self, selector: "stopUpdatingLocation:",
//			userInfo: nil, repeats: false)
		
		status = .Updating
		tableView.reloadData()
	}
	
	override func viewWillDisappear(animated: Bool)
	{
		println("\(self) disappear")
		
		locationManager.stopUpdatingLocation()
		locationManager.delegate = nil
		
		if timer != nil
		{
			timer.invalidate()
		}
	}
	
	// MARK: 数据重置
	
	@IBAction func reset(sender: UIBarButtonItem)
	{
		locationManager.stopUpdatingLocation()
		locationManager.delegate = nil
		
		measurements.removeAll(keepCapacity: false)
		bestMeasurement = nil
	}
	
	// MARK: 定位相关
	func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
	{
		var location = locations.first as CLLocation
		
		measurements.append(location)
		
		if bestMeasurement == nil || bestMeasurement.horizontalAccuracy > location.horizontalAccuracy
		{
			bestMeasurement = location
			
			if location.horizontalAccuracy < locationManager.desiredAccuracy
			{
				stopUpdatingLocation(.Acquired)
				
				timer.invalidate()
				timer = nil
			}
		}
	}
	
	func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!)
	{
		stopUpdatingLocation(.Error)
	}
	
	func stopUpdatingLocation(status:LocationUpdateStatus)
	{
		self.status = status
		
		tableView.reloadData()
		
		locationManager.stopUpdatingLocation()
		locationManager.delegate = nil
	}
	
	func updateTimedOut()
	{
		stopUpdatingLocation(.TimedOut)
	}
	
	// MARK: 列表展示
	
	override func numberOfSectionsInTableView(tableView: UITableView!) -> Int
	{
		return bestMeasurement != nil ? 3 : 1
	}
	
	override func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String!
	{
		if let type = SectionType.fromRaw(section)
		{
			switch type
			{
				case .LocateStatus:
					return localizeString("Status")
				
				case .BestMeasurement:
					return localizeString("Best Measurement")
				
				case .Measurements:
					return localizeString("All Measurements")
			}
		}
		else
		{
			return nil
		}
		
	}
	
	override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
	{
		if let type = SectionType.fromRaw(section)
		{
			switch type
			{
				case .LocateStatus:return 1
				case .BestMeasurement:return 1
				case .Measurements:return measurements.count
			}
		}
		else
		{
			return 0
		}
	}
	
	override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!
	{
		if let type = SectionType.fromRaw(indexPath.section)
		{
			switch type
			{
				case .LocateStatus:
					var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.Status.toRaw()) as StatusTableViewCell
					cell.label.text = localizeString(status.toRaw())
					if status == .Updating
					{
						if !cell.indicator.isAnimating()
						{
							cell.indicator.startAnimating()
						}
						
						println(cell.indicator.alpha)
					}
					else
					{
						if cell.indicator.isAnimating()
						{
							cell.indicator.stopAnimating()
						}
					}
					return cell
				
				case .BestMeasurement:
					var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.Measurement.toRaw()) as UITableViewCell
					cell.textLabel.text = bestMeasurement.localizedCoordinateString
					cell.detailTextLabel.text = dateFormatter.stringFromDate(bestMeasurement.timestamp)
					return cell
				
				case .Measurements:
					var location = measurements[indexPath.row]
					var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.Measurement.toRaw()) as UITableViewCell
					cell.textLabel.text = location.localizedCoordinateString
					cell.detailTextLabel.text = dateFormatter.stringFromDate(location.timestamp)
					return cell
			}
		}
		else
		{
			return nil
		}
	}
	
//	override func tableView(tableView: UITableView!, willSelectRowAtIndexPath indexPath: NSIndexPath!) -> NSIndexPath!
//	{
//		return SectionType.fromRaw(indexPath.section) == .LocateStatus ? nil : indexPath
//	}
}
