//
//  ViewController.swift
//  Regions
//
//  Created by doudou on 8/26/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate
{
                            
	@IBOutlet weak var map: MKMapView!
	
	private var locationManager:CLLocationManager!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		locationManager = CLLocationManager()
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.requestAlwaysAuthorization()
		locationManager.delegate = self
		locationManager.startUpdatingLocation()
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
	
	//MARK: 定位相关
	func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!)
	{
		map.setRegion(MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 1000.0, 1000.0), animated: true)
	}
	
	//MARK: 地图相关
	
}

	