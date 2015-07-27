//
//  LocationInfo+CoreDataProperties.swift
//  LocationTraker
//
//  Created by larryhou on 26/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension LocationInfo {

    @NSManaged var course: NSNumber?
    @NSManaged var horizontalAccuracy: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var speed: NSNumber?
    @NSManaged var timestamp: NSDate?
    @NSManaged var verticalAccuracy: NSNumber?
    @NSManaged var hitCount: NSNumber?
    @NSManaged var date: TrackTime?

}
