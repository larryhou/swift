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
	
	var title:String!
	var subtitle:String!
	
	init(coordinate:CLLocationCoordinate2D)
	{
		self.coordinate = coordinate
	}
}