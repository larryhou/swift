//
//  LocationTag+CoreDataProperties.swift
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

extension LocationTag {

    @NSManaged var name: String?
    @NSManaged var events: NSSet?

}
