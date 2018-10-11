//
//  ViewController.swift
//  NSURLConnection
//
//  Created by larryhou on 3/24/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController, NSURLConnectionDataDelegate {
	private var received: NSMutableData!

	override func viewDidLoad() {
		super.viewDidLoad()

		sendRequest()
	}

	// MARK: delegate

	func sendRequest() {
		received = NSMutableData()

		let request = NSURLRequest(URL: NSURL(string: "http://www.fiddler2.com")!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 60.0)
		var connection = NSURLConnection(request: request, delegate: self)
		connection?.start()
	}

	func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
		println(response)
	}

	func connection(connection: NSURLConnection, didReceiveData data: NSData) {
		println("data: \(data.length)")
		received.appendData(data)
	}

	func connection(connection: NSURLConnection, didFailWithError error: NSError) {
		println(error)
	}

	func connectionDidFinishLoading(connection: NSURLConnection) {
		println("done: \(received.length) = \(received.length / 1024)KB")
	}

	// MARK: redirect
	func connection(connection: NSURLConnection, willSendRequest request: NSURLRequest, redirectResponse response: NSURLResponse?) -> NSURLRequest? {
		if response != nil {
			println("redirect: \(response!) \n \(request)")
		}

		return request
	}

	// MARK: synchronous
	func sendSynchronousRequest() {
		let startime = NSDate()

		var error: NSError?
		var response: NSURLResponse?

		let request = NSURLRequest(URL: NSURL(string: "http://www.baidu.com")!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 60.0)
		let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)

		if error == nil {
			let contents = decodeNSString(response!, data: data!)
			println(response)
			println(contents)
		} else {
			println(error)
		}

		println(NSString(format: "elapse: %.3fms", NSDate().timeIntervalSinceDate(startime)))
	}

	func decodeNSString(response: NSURLResponse, data: NSData) -> NSString? {
		var cfencoding = CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
		var nsencoding = CFStringConvertEncodingToNSStringEncoding(cfencoding)

		if response.textEncodingName == "utf-8" {
			nsencoding = NSUTF8StringEncoding as NSStringEncoding
		}

		return NSString(data: data, encoding: nsencoding)
	}

	// MARK: asynchronous
	func sendAsynchronousRequest() {
		let startime = NSDate()

		var request = NSURLRequest(URL: NSURL(string: "http://www.baidu.com")!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 60.0)
		NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {
			(response: NSURLResponse!, data: NSData!, error: NSError!) in
			if error == nil {
				let contents = self.decodeNSString(response, data: data)
				println(response)
				println(contents)
			} else {
				println(error)
			}

			println(NSString(format: "finish: %.3fms", NSDate().timeIntervalSinceDate(startime)))
		})

		println(NSString(format: "send: %.3fms", NSDate().timeIntervalSinceDate(startime)))
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
