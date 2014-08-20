//
//  ViewController.swift
//  CLLocationManager
//
//  Created by larryhou on 8/19/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate
{
    var locationManager:CLLocationManager!
                            
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        println("LocationServiceEnabled:\(CLLocationManager.locationServicesEnabled())")
        
        locationManager = CLLocationManager()
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        
        locationManager.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: 定位相关
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!)
    {
        println(error)
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
    {
        println(locations.first)
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        println("status: \(status)")
    }

}

