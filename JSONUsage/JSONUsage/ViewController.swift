//
//  ViewController.swift
//  JSONUsage
//
//  Created by larryhou on 4/11/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController
{

	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		let url = NSBundle.mainBundle().URLForResource("0700", withExtension: "json")
		println(url)
		
		let data = NSData(contentsOfURL: url!)!
		var error:NSError?
		let result: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error)
		println(result?.dynamicType)
		if result != nil
		{
			let json = result as! [String:AnyObject]
			println(json)
		}
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

