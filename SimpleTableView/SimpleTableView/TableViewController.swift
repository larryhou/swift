//
//  ViewController.swift
//  SimpleTableView
//
//  Created by larryhou on 3/11/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

class GroupTableViewController: UITableViewController
{
    private var _list:[TimeZoneInfo]!
    
    private var _titles:[String]!
    private var _dict:[String:[TimeZoneInfo]]!

    override func viewDidLoad()
    {
        super.viewDidLoad()
		
        _list = TimeZoneModel.model.list
        _dict = TimeZoneModel.model.dict
        _titles = TimeZoneModel.model.keys
    }
	
    //MARK: basic
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return _dict.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        var key = _titles[section]
        return _dict[key]!.count
    }
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
	{
		return 44
	}
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell = tableView.dequeueReusableCellWithIdentifier("TimeZoneCell") as UITableViewCell
        
        var key = _titles[indexPath.section]
		(cell.viewWithTag(1) as UILabel).text = _dict[key]![indexPath.row].formattedString
        return cell
    }
    
    //MARK: index
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int
    {
        return index
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]!
    {
        return _titles
    }
    
    //MARK: header
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return _titles[section]
    }
	
	override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
	{
		return 32
	}
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}

class PlainTableViewController: UITableViewController
{
	private var _list:[TimeZoneInfo]!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		_list = TimeZoneModel.model.list
	}
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
		return 1
	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
	{
		return 44
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return _list.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		var cell = tableView.dequeueReusableCellWithIdentifier("TimeZoneCell") as UITableViewCell
		(cell.viewWithTag(1) as UILabel).text = _list[indexPath.row].formattedString
		return cell
	}
	
}

