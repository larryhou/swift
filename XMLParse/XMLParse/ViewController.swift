//
//  ViewController.swift
//  XMLParse
//
//  Created by larryhou on 3/27/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

func getpt<T>(inout target:T)->UnsafeMutablePointer<T>
{
	return withUnsafeMutablePointer(&target, {$0})
}

class ViewController: UIViewController, XMLReaderDelegate
{
	private var _data:NSDictionary!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		downloadRSSXML()
	}
	
	//MARK: download rss xml
	func downloadRSSXML()
	{
		let url = NSURL(string: "http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wpa/MRSS/newreleases/limit=300/rss.xml")!
		let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
		session.dataTaskWithRequest(NSURLRequest(URL: url), completionHandler:
		{
			(data:NSData!, response:NSURLResponse!, error:NSError!) in
			if error == nil
			{
				println(response)
				XMLReader().read(data, delegate: self)
			}
			else
			{
				println(error)
			}
		}).resume()
	}
	
	func readerDidFinishDocument(reader: XMLReader, data: NSDictionary, elapse: NSTimeInterval)
	{
		_data = data
		println("elapse: \(elapse)")
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
}

