//
//  LocationTag.swift
//  CoredataExample
//
//  Created by larryhou on 24/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import CoreData

@objc(LocationTag)
class LocationTag: NSManagedObject {
    func addTagsObject(value: LocationEvent) {
        mutableSetValueForKey("events").addObject(value)
    }

    func removeTagsObject(value: LocationEvent) {
        mutableSetValueForKey("events").removeObject(value)
    }

    func addTags(values: NSSet) {
        let list = mutableSetValueForKey("events")
        for item in values {
            list.addObject(item)
        }
    }

    func removeTags(values: NSSet) {
        let list = mutableSetValueForKey("events")
        for item in values {
            list.removeObject(item)
        }
    }
}
