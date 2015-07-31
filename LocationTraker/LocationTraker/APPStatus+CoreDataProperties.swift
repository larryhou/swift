//
//  APPStatus+CoreDataProperties.swift
//  LocationTraker
//
//  Created by larryhou on 31/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension APPStatus {

    @NSManaged var date: NSDate?
    @NSManaged var status: String?
    @NSManaged var timestamp: String?
    @NSManaged var data: NSData?

}
