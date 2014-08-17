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
	var localizedCoordinateString:String
	{
		if self.horizontalAccuracy < 0
		{
			return localizeString("DataUnavailable")
		}

		var latSuffix = self.coordinate.latitude < 0 ? localizeString("South") : localizeString("North")
		var lonSuffix = self.coordinate.longitude < 0 ? localizeString("West") : localizeString("East")
		return String(format: localizeString("LatLongFormat"), fabs(self.coordinate.latitude), latSuffix, fabs(self.coordinate.longitude), lonSuffix)
	}
	
	var localizedAltitudeString:String
	{
		if self.verticalAccuracy < 0
		{
			return localizeString("DataUnavailable")
		}
		
		var suffix:String = self.altitude < 0 ? localizeString("BelowSeaLevel") : localizeString("AboveSeaLevel")
		
		return String(format: localizeString("AltitudeFormat"), fabs(self.altitude), suffix)
	}
	
	var localizedHorizontalAccuracyString:String
	{
		
		if self.horizontalAccuracy < 0
		{
			return localizeString("DataUnavailable")
		}
			
		return String(format:localizeString("AccuracyFormat"), self.horizontalAccuracy)
	}
	
	var localizedVerticalAccuracyString:String
	{
		if self.verticalAccuracy < 0
		{
			return localizeString("DataUnavailable")
		}
			
		return String(format:localizeString("AccuracyFormat"), self.verticalAccuracy)
	}
	
	var localizedCourseString:String
	{
		if self.course < 0
		{
			return localizeString("DataUnavailable")
		}
			
		return String(format:localizeString("AccuracyFormat"), self.course)
	}
	
	var localizedSpeedString:String
	{
		if self.speed < 0
		{
			return localizeString("DataUnavailable")
		}
			
		return String(format:localizeString("AccuracyFormat"), self.speed)
	}
}