//
//  ViewController.swift
//  SimpleTableView
//
//  Created by larryhou on 3/11/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController
{
    private var _names:[String]!
    
    private var _indices:[String]!
    private var _data:[String:[String]]!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        _names = NSTimeZone.knownTimeZoneNames() as [String]
        _data = [:]
        
        _indices = []
        for i in 0..<_names.count
        {
            let key = _names[i].substringToIndex(advance(_names[i].startIndex, 1))
            
            if _data[key] == nil
            {
                _data[key] = [String]()
                _indices.append(key)
            }
            
            _names[i] = formatTimeZone(_names[i]) + " " + _names[i]
            _data[key]?.append(_names[i])
        }
        
        _indices.sort({$0 < $1})
        for (first, _) in _data
        {
            _data[first]?.sort({$0 < $1})
        }
        
        print(_indices)
    }
    
    private func formatTimeZone(name:String)->String
    {
        let zone = NSTimeZone(name: name)!
        let offset = zone.secondsFromGMT
        
        let hours = abs(offset) / 3600
        let minutes = abs(offset % 3600) / 60
        
        var result = NSString(format: "%02d:%02d", hours, minutes) as String
        result = "UTC" + (offset >= 0 ? "+" : "-") + result
        return result
    }
    
    //MARK: table view
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return _data.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        var key = _indices[section]
        return _data[key]!.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell = tableView.dequeueReusableCellWithIdentifier("TimeZoneCell") as UITableViewCell
        
        var key = _indices[indexPath.section]
        cell.textLabel?.text = _data[key]![indexPath.row]
        return cell
    }
    
    //MARK: index
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int
    {
        return index
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]!
    {
        return _indices
    }
    
    //MARK: header
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return _indices[section]
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

