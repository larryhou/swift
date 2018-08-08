//
//  ChinaGPS.swift
//  Regions
//
//  Created by doudou on 8/30/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//  参考资料：https://breeswish.org/blog/2013/10/17/google-map-offset-transform/
//

import Foundation
import CoreLocation

class ChinaGPS {
	class private func transformLon(x: Double, _ y: Double) -> Double {
		var lon = 300.0 + x + 2.0 * y + 0.1 * x * x
			lon += 0.1 * x * y + 0.1 * sqrt(fabs(x)) //FIXME: swift暂时不支持复杂的混合元算
		lon += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0
		lon += (20.0 * sin(x * M_PI) + 40.0 * sin(x / 3.0 * M_PI)) * 2.0 / 3.0
		lon += (150.0 * sin(x / 12.0 * M_PI) + 300.0 * sin(x / 30.0 * M_PI)) * 2.0 / 3.0

		return lon
	}

	class private func transformLat(x: Double, _ y: Double) -> Double {
		var lat = -100.0 + 2.0 * x + 3.0 * y
			lat += 0.2 * y * y + 0.1 * x * y
			lat += 0.2 * sqrt(fabs(x)) //FIXME: swift暂时不支持复杂的混合元算
		lat += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0
		lat += (20.0 * sin(y * M_PI) + 40.0 * sin(y / 3.0 * M_PI)) * 2.0 / 3.0
		lat += (160.0 * sin(y / 12.0 * M_PI) + 320 * sin(y * M_PI / 30.0)) * 2.0 / 3.0

		return lat
	}

	class func encrypt(latitude lat: Double, longitude lon: Double)->(latitude: Double, longitude: Double) {
		let A = 6378245.0
		let EE = 0.00669342162296594323

		var offset = (lat:0.0, lon:0.0)
		offset.lat = transformLat(lon - 105.0, lat - 35.0)
		offset.lon = transformLon(lon - 105.0, lat - 35.0)

		var radian = lat / 180.0 * M_PI

		var magic = sin(radian)
		magic = 1 - EE * magic * magic

		let MAGIC_SQRT = sqrt(magic)
		offset.lat = (offset.lat * 180.0) / ((A * (1 - EE)) / (magic * MAGIC_SQRT) * M_PI)
		offset.lon = (offset.lon * 180.0) / (A / MAGIC_SQRT * cos(radian) * M_PI)

		return (lat + offset.lat, lon + offset.lon)
	}

	class func encrypt(location: CLLocation) -> CLLocation {
		var gps = encrypt(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
		var ret = CLLocation(coordinate: CLLocationCoordinate2D(latitude: gps.latitude, longitude: gps.longitude),
							   altitude: location.altitude,
					 horizontalAccuracy: location.horizontalAccuracy,
					   verticalAccuracy: location.verticalAccuracy,
							  timestamp: location.timestamp)
		return ret
	}
}
