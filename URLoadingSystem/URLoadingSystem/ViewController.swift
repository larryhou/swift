//
//  ViewController.swift
//  URLoadingSystem
//
//  Created by larryhou on 3/23/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		performSessionTask()
	}

	func performSessionTask() {
		var proxy: [NSObject: AnyObject] = [:]
		proxy.updateValue(kCFProxyTypeHTTP, forKey: kCFProxyTypeKey)
		proxy.updateValue("proxy.tencent.com", forKey: kCFProxyHostNameKey)
		proxy.updateValue("8080", forKey: kCFProxyPortNumberKey)

		let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
		session.downloadTaskWithURL(NSURL(string: "https://www.baidu.com/")!, completionHandler: {
			(url: NSURL!, response: NSURLResponse!, _: NSError!) in

			let cfencoding = CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
			let nsencoding = CFStringConvertEncodingToNSStringEncoding(cfencoding)

			let contents = NSString(data: NSData(contentsOfURL: url)!, encoding: nsencoding)
			println(contents)
			println(response)

		}).resume()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
