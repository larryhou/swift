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
			var radian = atan2(refer.coordinate.latitude - location.coordinate.latitude, refer.coordinate.longitude - location.coordinate.longitude)
			self.subtitle = String(format:"纬:%.4f° 经:%.4f° 偏移:%.0f米/%.1f°", coordinate.latitude, coordinate.longitude, offset, radian * 180 / M_PI)
		}
		else
		{
			self.subtitle = String(format:"纬:%.4f° 经:%.4f°", coordinate.latitude, coordinate.longitude)
		}
	}
}