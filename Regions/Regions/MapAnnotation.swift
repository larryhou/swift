//
//  MapAnnotation.swift
//  Regions
//
//  Created by larryhou on 8/28/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import Foundation
import MapKit

class RegionAnnotationView:MKAnnotationView
{
	
}

class RegionAnnotation:NSObject, MKAnnotation
{
	var coordinate:CLLocationCoordinate2D
	
	var title:String!
	var subtitle:String!
	
	init(coordinate:CLLocationCoordinate2D)
	{
		self.coordinate = coordinate
	}
}

class DeviceAnnotation:NSObject, MKAnnotation
{
	var coordinate:CLLocationCoordinate2D
	var location:CLLocation
	
	var title:String
	var subtitle:String!
	
	init(location:CLLocation)
	{
		self.coordinate = location.coordinate
		self.location = location
		
		self.title = "CLLocationManager定位"
		self.subtitle = String(format:"纬度:%.6f° 经度:%.6f°", coordinate.latitude, coordinate.longitude)
	}
}

class DeviceAnnotationView:MKAnnotationView
{
	var deviceAnnotation:DeviceAnnotation!
	
	init(annotation:DeviceAnnotation)
	{
		self.deviceAnnotation = annotation
		super.init(annotation: annotation, reuseIdentifier: "DeviceAnnotationView")
	}
	
	required init(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
}