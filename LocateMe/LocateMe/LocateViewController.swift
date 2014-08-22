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
	case Timeout = "Timeout"
	case Acquired = "Acquired Location"
	case Error = "Error"
    case None = "None"
}

extension CLAuthorizationStatus
{
    var description:String
    {
        var status:String
        switch self
        {
            case .Authorized:status="Authorized"
            case .AuthorizedWhenInUse:status="AuthorizedWhenInUse"
            case .Denied:status="Denied"
            case .NotDetermined:status="NotDetermined"
            case .Restricted:status="Restriced"
        }
            
        return "CLAuthorizationStatus.\(status)"
    }
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
    }
    
    override func viewWillAppear(animated: Bool)
    {
        if bestMeasurement == nil
        {
            startUpdateLocation()
        }
	}
	
	override func viewWillDisappear(animated: Bool)
	{
		stopUpdatingLocation(.None)
	}
	
	// MARK: 数据重置
    @IBAction func refresh(sender: UIBarButtonItem)
    {
        startUpdateLocation()
    }
	
	// MARK: 定位相关
    func startUpdateLocation()
    {
        if timer != nil
        {
            timer.invalidate()
            timer = nil
        }
        
        locationManager.stopUpdatingLocation()
        
        measurements.removeAll(keepCapacity: false)
        bestMeasurement = nil
        
        status = .Updating
        tableView.reloadData()
        
        println(setting)
        
        var delay:NSTimeInterval = NSTimeInterval(setting.sliderValue)
        timer = NSTimer.scheduledTimerWithTimeInterval(delay,
            target: self, selector: "updateLocationTimeout",
            userInfo: nil, repeats: false)
        
        // FIXME: 无法使用带参数的selector，否则报错： [NSCFTimer copyWithZone:]: unrecognized selector sent to instance
        //			timer = NSTimer.scheduledTimerWithTimeInterval(delay,
        //			target: self, selector: "stopUpdatingLocation:",
        //			userInfo: nil, repeats: false)
        
        if (CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedWhenInUse)
        {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.desiredAccuracy = setting.accuracy
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation(status:LocationUpdateStatus)
    {
        if status != .None
        {
            self.status = status
            tableView.reloadData()
        }
        
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        
        if timer != nil
        {
            timer.invalidate()
            timer = nil
        }
    }
    
    func updateLocationTimeout()
    {
        stopUpdatingLocation(.Timeout)
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        println("authorization:\(status.description)")
    }
    
	func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
	{
        for data in locations
        {
            var location = data as CLLocation
            println("radius:\(location.horizontalAccuracy), altitude:\(location.verticalAccuracy)")
            
            measurements.append(location)
            
            if bestMeasurement == nil || bestMeasurement.horizontalAccuracy > location.horizontalAccuracy
            {
                bestMeasurement = location
                if location.horizontalAccuracy < locationManager.desiredAccuracy
                {
                    stopUpdatingLocation(.Acquired)
                }
            }
        }
        
        tableView.reloadData()
	}
	
	func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!)
	{
		stopUpdatingLocation(.Error)
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
					var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.Status.toRaw()) as UITableViewCell
					cell.textLabel.text = localizeString(status.toRaw())
//					if status == .Updating
//					{
//						if !cell.indicator.isAnimating()
//						{
//							cell.indicator.startAnimating()
//						}
//					}
//					else
//					{
//						if cell.indicator.isAnimating()
//						{
//							cell.indicator.stopAnimating()
//						}
//					}
					return cell
				
				case .BestMeasurement:
					var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.Measurement.toRaw()) as UITableViewCell
					cell.textLabel.text = bestMeasurement.getCoordinateString()
					cell.detailTextLabel.text = dateFormatter.stringFromDate(bestMeasurement.timestamp)
					return cell
				
				case .Measurements:
					var location = measurements[indexPath.row]
					var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.Measurement.toRaw()) as UITableViewCell
					cell.textLabel.text = location.getCoordinateString()
					cell.detailTextLabel.text = dateFormatter.stringFromDate(location.timestamp)
					return cell
			}
		}
		else
		{
			return nil
		}
	}
    
    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
	
	//MARK: segue
	override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!)
	{
		if segue.identifier == "LocationDetailSegue"
		{
			var indexPath = tableView.indexPathForCell(sender as UITableViewCell)
			var type:SectionType = SectionType.fromRaw(indexPath.section)!
			
			var destinationCtrl = segue.destinationViewController as LocationDetailViewController
			
			switch type
			{
				case .BestMeasurement:
					destinationCtrl.location = bestMeasurement
				case .Measurements:
					destinationCtrl.location = measurements[indexPath.row]
				default:break
			}
		}
	}
	
}
