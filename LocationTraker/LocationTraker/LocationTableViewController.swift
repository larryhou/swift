//
//  LocationTableViewController.swift
//  LocationTraker
//
//  Created by larryhou on 27/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import CoreLocation
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
        text += String(format: " %.5f°,%.5f°", location.latitude!.doubleValue, location.longitude!.doubleValue)
        cell.textLabel?.text = text
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let info = data[indexPath.row]
        let location = ChinaGPS.encrypt_WGS_2_GCJ(latitude: info.latitude!.doubleValue, longitude: info.longitude!.doubleValue)
        
        CLGeocoder().reverseGeocodeLocation(location)
        { (ret:[CLPlacemark]?, error:NSError?) in
            if error == nil
            {
                self.alertPlacemark(CLLocation(latitude: info.latitude!.doubleValue, longitude: info.longitude!.doubleValue), marsloc:location, placemarks: ret!)
            }
            else
            {
                print(error)
            }
        }
    }
    
    func alertPlacemark(location:CLLocation, marsloc:CLLocation, placemarks:[CLPlacemark])
    {
        func loc2str(location:CLLocation) -> String
        {
            return String(format: "%.10f°, %.10f°", location.coordinate.latitude, location.coordinate.longitude)
        }
        
        let biduloc = ChinaGPS.baidu_encrypt(latitude: marsloc.coordinate.latitude, longitude: marsloc.coordinate.longitude)
        
        let message = loc2str(location)
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let operation:(UIAlertAction -> Void) = { self.setClipboard($0.title!)}
        
        for item in placemarks
        {
            let addrs = item.addressDictionary?["FormattedAddressLines"] as! [String]
            print(addrs)
            
            var actions:[UIAlertAction] = []
            actions.append(UIAlertAction(title: loc2str(marsloc), style: UIAlertActionStyle.Default, handler: operation))
            actions.append(UIAlertAction(title: loc2str(biduloc), style: UIAlertActionStyle.Default, handler: operation))
            actions.append(UIAlertAction(title: addrs.first, style: UIAlertActionStyle.Default, handler: operation))
            if item.areasOfInterest != nil
            {
                actions += item.areasOfInterest!.map
                {
                     return UIAlertAction(title: $0, style: UIAlertActionStyle.Default, handler: operation)
                }
            }
            actions.append(UIAlertAction(title: "I've got it!", style: UIAlertActionStyle.Cancel, handler: { _ in self.setClipboard(message) }))
            for action in actions
            {
                alert.addAction(action)
            }
        }
        
        presentViewController(alert, animated: true
            , completion: nil)
    }
    
    func setClipboard(text:String)
    {
        UIPasteboard.generalPasteboard().string = text
    }
    
    //MARK: segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "ShowLocationDetail"
        {
            let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)!
            let location = data[indexPath.row]
            
            let dstCtrl = segue.destinationViewController as! LocationDetailTableViewController
            dstCtrl.location = location
        }
    }
    
    deinit
    {
        currentTime.removeObserver(self, forKeyPath: "locations", context: &CONTEXT_LOCATION_UPDATE)
    }
}