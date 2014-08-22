//
//  CLLocation(strings).swift
//  LocateMe
//
//  Created by doudou on 8/17/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocation
{
	func getCoordinateString()->String
	{
		if self.horizontalAccuracy < 0
		{
			return localizeString("DataUnavailable")
		}

		var latSuffix = self.coordinate.latitude < 0 ? localizeString("South") : localizeString("North")
		var lonSuffix = self.coordinate.longitude < 0 ? localizeString("West") : localizeString("East")
		return String(format: localizeString("LatLongFormat"), fabs(self.coordinate.latitude), latSuffix, fabs(self.coordinate.longitude), lonSuffix)
	}
	
	func getLatitudeString()->String
	{
		var suffix = self.coordinate.latitude < 0 ? localizeString("South") : localizeString("North")
		return String(format:localizeString("LocationFormat"), fabs(self.coordinate.latitude), suffix);
	}
	
	func getLongitudeString()->String
	{
		var suffix = self.coordinate.longitude < 0 ? localizeString("West") : localizeString("East")
		return String(format:localizeString("LocationFormat"), fabs(self.coordinate.longitude), suffix);
	}
	
	func getAltitudeString()->String
	{
		if self.verticalAccuracy < 0
		{
			return localizeString("DataUnavailable")
		}
		
		var suffix:String = self.altitude < 0 ? localizeString("BelowSeaLevel") : localizeString("AboveSeaLevel")
		
		return String(format: localizeString("AltitudeFormat"), suffix, fabs(self.altitude))
	}
	
	func getHorizontalAccuracyString()->String
	{
		
		if self.horizontalAccuracy < 0
		{
			return localizeString("DataUnavailable")
		}
			
		return String(format:localizeString("AccuracyFormat"), self.horizontalAccuracy)
	}
	
	func getVerticalAccuracyString()->String
	{
		if self.verticalAccuracy < 0
		{
			return localizeString("DataUnavailable")
		}
			
		return String(format:localizeString("AccuracyFormat"), self.verticalAccuracy)
	}
	
	func getCourseString()->String
	{
		if self.course < 0
		{
			return localizeString("DataUnavailable")
		}
			
		return String(format:localizeString("AccuracyFormat"), self.course)
	}
	
	func getSpeedString()->String
	{
		if self.speed < 0
		{
			return localizeString("DataUnavailable")
		}
			
		return String(format:localizeString("AccuracyFormat"), self.speed)
	}
}