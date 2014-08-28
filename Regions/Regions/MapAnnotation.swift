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
	var location:CLLocation!
	
	var title:String
	var subtitle:String!
	
	init(coordinate:CLLocationCoordinate2D)
	{
		self.coordinate = coordinate
		self.title = "CL/API定位"
	}
	
	func updateLocation(location:CLLocation, refer:CLLocation!)
	{
		if refer != nil
		{
			var offset = location.distanceFromLocation(refer)
			self.subtitle = String(format:"纬度:%.6f° 经度:%.6f° 偏移:%.1f米", coordinate.latitude, coordinate.longitude, offset)
		}
		else
		{
			self.subtitle = String(format:"纬度:%.6f° 经度:%.6f°", coordinate.latitude, coordinate.longitude)
		}
	}
}