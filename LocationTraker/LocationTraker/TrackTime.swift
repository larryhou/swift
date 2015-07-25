//
//  TrackTime.swift
//  LocationTraker
//
//  Created by larryhou on 25/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import CoreData

@objc(TrackTime)
class TrackTime: NSManagedObject
{
    func addLocationsObject(value:LocationInfo)
    {
        mutableSetValueForKey("locations").addObject(value)
    }
    
    func removeLocationsObject(value:LocationInfo)
    {
        mutableSetValueForKey("locations").removeObject(value)
    }
    
    func addLocations(values:NSSet)
    {
        let list = mutableSetValueForKey("locations")
        for item in values
        {
            list.addObject(item)
        }
    }
    
    func removeLocations(values:NSSet)
    {
        let list = mutableSetValueForKey("locations")
        for item in values
        {
            list.removeObject(item)
        }
    }
}
