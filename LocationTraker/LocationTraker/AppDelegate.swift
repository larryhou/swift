//
//  AppDelegate.swift
//  LocationTraker
//
//  Created by larryhou on 25/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{

    var window: UIWindow?
    var trackController:TrackTimeTableViewController!
    var formatter:NSDateFormatter!


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        if launchOptions != nil
        {
            for (key, value) in launchOptions!
            {
                print("\(key): \(value)")
            }
        }
        
        formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd E HH:mm:ss.SSS"
        
        trackController = (window!.rootViewController as! UINavigationController).topViewController as! TrackTimeTableViewController
        trackController.managedObjectContext = managedObjectContext
        
        insertAPPStatus(APPStatusType.Launch)
        return true
    }
    
    func insertAPPStatus(type:APPStatusType)
    {
        let date = NSDate()
        let status = NSEntityDescription.insertNewObjectForEntityForName("APPStatus", inManagedObjectContext: managedObjectContext) as! APPStatus
        status.timestamp = formatter.stringFromDate(date)
        status.status = type.rawValue
        status.date = date
        
        do
        {
            try managedObjectContext.save()
        }
        catch {}
    }
    
    func cleanUpStatus()
    {
        let request = NSFetchRequest(entityName: "APPStatus")
        request.predicate = NSPredicate(format: "date != nil")
        request.resultType = NSFetchRequestResultType.ManagedObjectIDResultType
        
        do
        {
            let ids = try managedObjectContext.executeFetchRequest(request) as! [NSManagedObjectID]
            if ids.count > 0
            {
                let deleteRequest = NSBatchDeleteRequest(objectIDs: ids)
                try managedObjectContext.executeRequest(deleteRequest)
            }
        }
        catch
        {
            print(error)
        }
    }

    func applicationWillResignActive(application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print(__FUNCTION__)
        insertAPPStatus(APPStatusType.ResignActive)
    }

    func applicationDidEnterBackground(application: UIApplication)
    {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print(__FUNCTION__)
        trackController.enterBackgroundMode()
        insertAPPStatus(APPStatusType.EnterBackground)
    }

    func applicationWillEnterForeground(application: UIApplication)
    {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print(__FUNCTION__)
        trackController.enterForegroundMode()
        insertAPPStatus(APPStatusType.EnterForeground)
    }

    func applicationDidBecomeActive(application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print(__FUNCTION__)
        insertAPPStatus(APPStatusType.BecomeActive)
    }

    func applicationWillTerminate(application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        print(__FUNCTION__)
        self.saveContext()
        insertAPPStatus(APPStatusType.Terminate)
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL =
    {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.larryhou.samples.LocationTraker" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel =
    {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("LocationTraker", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator =
    {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("data.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do
        {
            var params:[String:AnyObject] = [:]
            params.updateValue(true, forKey: NSMigratePersistentStoresAutomaticallyOption)
            params.updateValue(true, forKey: NSInferMappingModelAutomaticallyOption)
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: params)
        }
        catch
        {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext =
    {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext ()
    {
        if managedObjectContext.hasChanges
        {
            do
            {
                try managedObjectContext.save()
            }
            catch
            {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}

