//
//  ViewController.swift
//  NSURLDownload
//
//  Created by larryhou on 3/25/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import Cocoa
import Foundation
import AppKit
import WebKit

class ViewController: NSViewController, NSURLDownloadDelegate
{

	@IBOutlet weak var indicator: NSProgressIndicator!
	@IBOutlet weak var web: WebView!
	
	private var received = 0.0
	private var total = 0.0
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		start()
	}
	
	func start()
	{
		let url = NSURL(string: "http://dldir1.qq.com/qqfile/QQforMac/QQ_V4.0.2.dmg")
		if url == nil
		{
			println("Cann't create NSURL object!")
			return
		}
		
		var request = NSURLRequest(URL: url!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 60.0)
		var download = NSURLDownload(request: request, delegate: self)
		download.deletesFileUponFailure = false
		println(download)
		
		indicator.doubleValue = 0
		indicator.usesThreadedAnimation = true
		
		request = NSURLRequest(URL: NSURL(string: "http://im.qq.com")!)
		web.mainFrame.loadRequest(request)
	}
	
	func download(download: NSURLDownload, decideDestinationWithSuggestedFilename filename: String)
	{
		let path = NSHomeDirectory().stringByAppendingPathComponent("Desktop").stringByAppendingPathComponent(filename)
		
		download.setDestination(path, allowOverwrite: true)
	}
	
	func download(download: NSURLDownload, didCreateDestination path: String)
	{
		NSLog("%@", "created: \(path)")
	}
	
	func download(download: NSURLDownload, didReceiveResponse response: NSURLResponse)
	{
		total = Double(response.expectedContentLength)
		indicator.doubleValue = 0
		
		NSLog("%@", response)
	}
	
	func downloadDidBegin(download: NSURLDownload)
	{
		NSLog("%@", "begin")
	}
	
	func download(download: NSURLDownload, didReceiveDataOfLength length: Int)
	{
		received += Double(length)
		indicator.doubleValue = received * 100 / total
		NSLog("data: %6d \t %.2f%", length, received * 100 / total)
	}
	
	func downloadDidFinish(download: NSURLDownload)
	{
		NSLog("%@", "finish")
	}
	
	func download(download: NSURLDownload, didFailWithError error: NSError)
	{
		NSLog("%@", error)
		println(error)
	}

	override var representedObject: AnyObject?
	{
		didSet
		{
			// Update the view, if already loaded.
		}
	}
}

