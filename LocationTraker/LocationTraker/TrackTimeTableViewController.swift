//
//  ViewController.swift
//  LocationTraker
//
//  Created by larryhou on 25/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class TrackTimeTableViewController: UITableViewController, CLLocationManagerDelegate
{
    var managedObjectContext:NSManagedObjectContext!
    
    private var data:[TrackTime]!
    private var formatter:NSDateFormatter!
    
    private var currentTime:TrackTime!
    private var currentLocation:LocationInfo!
    
    private var locationManager:CLLocationManager!
    private var monitering:Bool = false

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        formatter = NSDateFormatter()
        
        let request = NSFetchRequest(entityName: "TrackTime")
        request.fetchBatchSize = 20
        request.resultType = NSFetchRequestResultType.ManagedObjectResultType
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do
        {
            data = try managedObjectContext.executeFetchRequest(request) as! [TrackTime]
            currentTime = data.first
        }
        catch
        {
            print(error)
            data = []
        }
        
        locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    //MARK: states change
    func enterBackgroundMode()
    {
        locationManager.stopUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func enterForegroundMode()
    {
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()
    }
    
    //MARK: location
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        print(status)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        for location in locations
        {
            addUpdatedLocation(location)
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
    {
        print(error)
    }
    
    //MARK: insert SQL
    func getCLLocation(location:LocationInfo)->CLLocation
    {
        return CLLocation(latitude: location.latitude!.doubleValue, longitude: location.longitude!.doubleValue)
    }
    
    func addUpdatedLocation(newloc:CLLocation) -> Bool
    {
        var contextChanged = false
        
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.stringFromDate(newloc.timestamp)
        if currentTime == nil || date != currentTime.date
        {
            contextChanged = true
            currentTime = NSEntityDescription.insertNewObjectForEntityForName("TrackTime", inManagedObjectContext: managedObjectContext) as! TrackTime
            currentTime.date = date
            
            data.append(currentTime)
            
            tableView.reloadData()
        }
        
        if currentLocation == nil || getCLLocation(currentLocation).distanceFromLocation(newloc) >= 1.0
        {
            contextChanged = true
            let location = NSEntityDescription.insertNewObjectForEntityForName("LocationInfo", inManagedObjectContext: managedObjectContext) as! LocationInfo
            location.date = currentTime
            
            currentLocation = location
            currentLocation.latitude = newloc.coordinate.latitude
            currentLocation.longitude = newloc.coordinate.longitude
            currentLocation.speed = newloc.speed
            currentLocation.course = newloc.course
            currentLocation.horizontalAccuracy = newloc.horizontalAccuracy
            currentLocation.verticalAccuracy = newloc.verticalAccuracy
            currentLocation.altitude = newloc.altitude
            currentLocation.timestamp = newloc.timestamp
        }
        
        if contextChanged
        {
            do
            {
                try managedObjectContext.save()
            }
            catch
            {
                print(error)
            }
        }
        
        return contextChanged
    }
    
    //MARK: table
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return data.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("TrackTimeCell")!
        cell.textLabel?.text = data[indexPath.row].date
        return cell
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}

