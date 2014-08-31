//
//  MapAnnotation.swift
//  Regions
//
//  Created by larryhou on 8/28/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import Foundation
import MapKit

class RegionAnnotation:NSObject, MKAnnotation
{
	var coordinate:CLLocationCoordinate2D
	var region:CLCircularRegion
	
	var title:String!
	var subtitle:String!
	
	init(coordinate:CLLocationCoordinate2D, region:CLCircularRegion)
	{
		self.coordinate = coordinate
		self.region = region
		
		self.title = String(format:"纬度: %.4f° 经度: %.4f°", coordinate.latitude, coordinate.longitude)
	}
	
	func update(#location:CLLocation!)
	{
		if location != nil
		{
			self.coordinate = location.coordinate
			self.title = String(format:"纬度:%.4f° 经度%.4f°", location.coordinate.latitude, location.coordinate.longitude)
			self.subtitle = String(format:"精度:%.2f米", location.horizontalAccuracy)
		}
		else
		{
			self.title = nil
			self.subtitle = nil
		}
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