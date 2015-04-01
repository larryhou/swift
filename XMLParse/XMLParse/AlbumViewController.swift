//
//  AlbumViewController.swift
//  XMLParse
//
//  Created by larryhou on 3/31/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import Foundation
import UIKit

class AlbumViewController:UIViewController, UIWebViewDelegate
{
	@IBOutlet weak var browser: UIWebView!
	var path:String!
	@IBOutlet weak var loading: UIActivityIndicatorView!
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		let url = NSURL(string: path)
		
		if url != nil
		{
			println(path)
			
//			browser.loadRequest(NSURLRequest(URL: url!))
			
			loading.startAnimating()
			loading.hidden = false
			
			NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: url!))
			{
				(data:NSData!, response:NSURLResponse!, error:NSError!) in
				
				dispatch_async(dispatch_get_main_queue())
				{
					self.browser.loadData(data, MIMEType: "text/html", textEncodingName: response.textEncodingName, baseURL: nil)
					self.loading.hidden = true
				}
			}.resume()
		}
		else
		{
			UIAlertView(title: nil, message: "URL[=\(path)] NOT AVAILABLE", delegate: nil, cancelButtonTitle: nil).show()
		}
		
	}
	
//	func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool
//	{
//		return false
//	}
}