//
//  ViewController.swift
//  UIWebView
//
//  Created by larryhou on 3/27/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{

	@IBOutlet weak var web: UIWebView!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		let path = NSBundle.mainBundle().pathForResource("html", ofType: "data");
		if path == nil
		{
			println("path not exist")
		}
		else
		{
			let data = NSData(contentsOfFile: path!)
			web.loadData(data!, MIMEType: "text/html", textEncodingName: "utf-8", baseURL: nil)
		}
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
}

