//
//  MapAnnotation.swift
//  Regions
//
//  Created by larryhou on 8/28/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import Foundation
import MapKit

class RegionAnnotation: NSObject, MKAnnotation {
	dynamic var coordinate: CLLocationCoordinate2D
	var region: CLCircularRegion

	dynamic var title: String!
	dynamic var subtitle: String!

	init(coordinate: CLLocationCoordinate2D, region: CLCircularRegion) {
		self.coordinate = coordinate
		self.region = region

		self.title = String(format: "纬度: %.4f° 经度: %.4f°", coordinate.latitude, coordinate.longitude)
	}

	func update(#location:CLLocation!) {
		if location != nil {
			self.coordinate = location.coordinate
			self.title = String(format: "纬度:%.4f° 经度%.4f°", location.coordinate.latitude, location.coordinate.longitude)
			self.subtitle = String(format: "精度:%.2f米", location.horizontalAccuracy)
		} else {
			self.title = nil
			self.subtitle = nil
		}
	}
}

class DeviceAnnotation: NSObject, MKAnnotation {
	dynamic var coordinate: CLLocationCoordinate2D
	dynamic var location: CLLocation!

	dynamic var title: String!
	dynamic var subtitle: String!

	init(coordinate: CLLocationCoordinate2D) {
		self.coordinate = coordinate
		super.init()

		update(coordinate: coordinate)
	}

	func update(#location:CLLocation) {
		self.location = location
		update(coordinate: location.coordinate)
	}

	func update(#coordinate:CLLocationCoordinate2D) {
		self.title = String(format: "纬:%.6f° 经:%.6f°", coordinate.latitude, coordinate.longitude)
	}

	func update(#placemark:CLPlacemark) {
		self.subtitle = placemark.name.componentsSeparatedByString(placemark.administrativeArea).last
	}
}
