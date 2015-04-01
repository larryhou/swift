//
//  ViewController.swift
//  StoreProductView
//
//  Created by larryhou on 4/1/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit
import StoreKit

class ViewController: UIViewController, SKStoreProductViewControllerDelegate
{

	override func viewDidLoad()
	{
		super.viewDidLoad()
		previewiTunesProduct(414478124)
	}
	
	func previewiTunesProduct(id:Double)
	{
		var controller = SKStoreProductViewController()
		controller.delegate = self
		controller.loadProductWithParameters([SKStoreProductParameterITunesItemIdentifier:id], completionBlock: nil)
		presentViewController(controller, animated: true, completion: nil)
		
	}
	
	func productViewControllerDidFinish(viewController: SKStoreProductViewController!)
	{
		println("done")
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

