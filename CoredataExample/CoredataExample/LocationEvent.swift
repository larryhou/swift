//
//  LocationEvent.swift
//  CoredataExample
//
//  Created by larryhou on 24/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import CoreData

@objc(LocationEvent)
class LocationEvent: NSManagedObject {
    func addTagsObject(value: LocationTag) {
        mutableSetValueForKey("tags").addObject(value)
    }

    func removeTagsObject(value: LocationTag) {
        mutableSetValueForKey("tags").removeObject(value)
    }

    func addTags(values: NSSet) {
        let list = mutableSetValueForKey("tags")
        for item in values {
            list.addObject(item)
        }
    }

    func removeTags(values: NSSet) {
        let list = mutableSetValueForKey("tags")
        for item in values {
            list.removeObject(item)
        }
    }
}
