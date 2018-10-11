//
//  ViewController.swift
//  CoredataExample
//
//  Created by larryhou on 19/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    var managedObjectContext: NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()

//        let tag = NSEntityDescription.insertNewObjectForEntityForName("LocationTag", inManagedObjectContext: managedObjectContext) as! LocationTag
//        tag.name = "jason"
//        do
//        {
//            try managedObjectContext.save()
//            print(tag.objectID)
//        }
//        catch
//        {
//            print(error)
//        }
//        
//        managedObjectContext.deleteObject(tag)
//        print(tag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
