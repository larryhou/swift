//
//  APPStatus.swift
//  LocationTraker
//
//  Created by larryhou on 29/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import CoreData

@objc(APPStatus)
class APPStatus: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

}

enum APPStatusType: String {
    case Launch = "Launch"
    case EnterBackground = "EnterBackground"
    case EnterForeground = "EnterForeground"
    case BecomeActive = "BecomeActive"
    case ResignActive = "ResignActive"
    case Terminate = "Terminate"
}
