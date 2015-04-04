//
//  ViewController.swift
//  MapAnnotation
//
//  Created by larryhou on 4/4/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit
import MapKit

class MapPinAnnotation:NSObject, MKAnnotation
{
	var coordinate:CLLocationCoordinate2D
	var title:String
	
	init(coordinate:CLLocationCoordinate2D)
	{
		self.coordinate = coordinate
		self.title = NSString(format:"%.4f°/%.4f°", coordinate.latitude, coordinate.latitude)
	}
}

class ViewController: UIViewController, MKMapViewDelegate
{
	@IBOutlet weak var map: MKMapView!
	private var _locationManager:CLLocationManager!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		_locationManager = CLLocationManager()
		_locationManager.requestAlwaysAuthorization()
		
		map.showsUserLocation = true
	}
	
	func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!)
	{
		let location = map.userLocation.location
		
		map.setRegion(MKCoordinateRegionMakeWithDistance(location.coordinate, 200, 200), animated: true)
		map.showsUserLocation = false
		
		map.addAnnotation(MapPinAnnotation(coordinate: location.coordinate))
	}
	
	func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView!
	{
		if annotation.isKindOfClass(MapPinAnnotation)
		{
			let REUSE_IDENTIFIER = "MapPinAnnotation"
			var anView = map.dequeueReusableAnnotationViewWithIdentifier(REUSE_IDENTIFIER) as? MKPinAnnotationView
			if anView == nil
			{
				anView = MKPinAnnotationView(annotation: nil, reuseIdentifier: REUSE_IDENTIFIER)
				anView!.canShowCallout = true
				anView!.animatesDrop = true
			}
			
			anView!.annotation = annotation
			return anView
		}
		
		return nil
	}
	
	func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!)
	{
		let anView = views.first as MKPinAnnotationView
		map.selectAnnotation(anView.annotation, animated: true)
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}


}

