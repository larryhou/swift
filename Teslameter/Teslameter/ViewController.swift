//
//  ViewController.swift
//  Teslameter
//
//  Created by larryhou on 9/18/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
	@IBOutlet var magnitude: UILabel!
	@IBOutlet var graph: UIView!
	
	@IBOutlet var teslaX: UILabel!
	@IBOutlet var teslaY: UILabel!
	@IBOutlet var teslaZ: UILabel!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		println("magnitude \(magnitude.frame)")
		println("graph \(graph.frame)")
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
}