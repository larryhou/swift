//
//  ViewController.swift
//  Regions
//
//  Created by doudou on 8/26/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class RegionViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate
{
                            
	@IBOutlet weak var map: MKMapView!
	
	private var locationManager:CLLocationManager!
	
	private var deviceAnnotation:DeviceAnnotation!
	private var isUpdated:Bool!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		map.delegate = self
		map.region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: 22.55, longitude: 113.94), 1000, 1000)
		
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
	
	override func viewWillAppear(animated: Bool)
	{
		isUpdated = false
	}
	
	@IBAction func showDeviceLocation(sender: UIBarButtonItem)
	{
		if map.userLocation != nil
		{
			map.setCenterCoordinate(map.userLocation.coordinate, animated: true)
		}
	}

	//MARK: 地图相关
	func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView!
	{
		if annotation.isKindOfClass(DeviceAnnotation)
		{
			let identifier = "DeviceAnnotationView"
			var annotionView = map.dequeueReusableAnnotationViewWithIdentifier(identifier) as MKPinAnnotationView!
			if annotionView == nil
			{
				annotionView = MKPinAnnotationView(annotation: deviceAnnotation, reuseIdentifier: identifier)
				annotionView.canShowCallout = true
				annotionView.pinColor = MKPinAnnotationColor.Purple
				
			}
			else
			{
				annotionView.annotation = annotation
			}
			
			return annotionView
		}
		
		return nil
	}
	
	//MARK: 定位相关
	func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!)
	{
		var location = ChinaGPS.encrypt(newLocation)
		println("CLLocationManager", location.coordinate.latitude, location.coordinate.longitude)
		
		if deviceAnnotation == nil
		{
			deviceAnnotation = DeviceAnnotation(coordinate: location.coordinate)
		}
		else
		{
			deviceAnnotation.coordinate = location.coordinate
		}
		
		deviceAnnotation.updateLocation(location, refer: map.userLocation.location)

		map.removeAnnotation(deviceAnnotation)

		map.addAnnotation(deviceAnnotation)
		map.selectAnnotation(deviceAnnotation, animated: false)
	}
	
	//MARK: 地图相关
	func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!)
	{
		println("MKMapView", userLocation.coordinate.latitude, userLocation.coordinate.longitude)
		if !isUpdated
		{
			map.setCenterCoordinate(userLocation.coordinate, animated: true)
			isUpdated = true
		}
	}
}

	