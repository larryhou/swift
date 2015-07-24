//
//  LocationEvent+CoreDataProperties.swift
//  CoredataExample
//
//  Created by larryhou on 24/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension LocationEvent
{

    @NSManaged var date: NSDate?
    @NSManaged var id: NSNumber?
    @NSManaged var latitude: NSDecimalNumber?
    @NSManaged var longitude: NSDecimalNumber?
    @NSManaged var name: String?
    @NSManaged var tags: NSSet?

}
