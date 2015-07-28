//
//  LocationTableViewController.swift
//  LocationTraker
//
//  Created by larryhou on 27/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import UIKit

class LocationTableViewController:UITableViewController
{
    var CONTEXT_LOCATION_UPDATE:String?
    
    var currentTime:TrackTime!
    private var data:[LocationInfo]!
    private var formatter:NSDateFormatter!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        formatter = NSDateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        updateTrackedLocations()
        currentTime.addObserver(self, forKeyPath: "locations", options: NSKeyValueObservingOptions.New, context: &CONTEXT_LOCATION_UPDATE)
    }
    
    private func updateTrackedLocations()
    {
        data = currentTime.locations?.allObjects as! [LocationInfo]
        data.sortInPlace{ $0.timestamp?.timeIntervalSince1970 > $1.timestamp?.timeIntervalSince1970}
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if context == &CONTEXT_LOCATION_UPDATE
        {
            for item in (currentTime.locations?.allObjects)!
            {
                (item as! LocationInfo).timestamp == nil // fire faulting
            }
            
            performSelector("updateTableView", withObject: nil, afterDelay: 0)
        }
    }
    
    func updateTableView()
    {
        updateTrackedLocations()
        tableView.reloadData()
    }
    
    //MARK: table
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return data.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let location = data[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("LocationCell")!
        
        var text = formatter.stringFromDate(location.timestamp!)
        text += String(format: " %11.7f°,%11.7f°", location.latitude!.doubleValue, location.longitude!.doubleValue)
        cell.textLabel?.text = text
        
        return cell
    }
    
    deinit
    {
        currentTime.removeObserver(self, forKeyPath: "locations", context: &CONTEXT_LOCATION_UPDATE)
    }
}