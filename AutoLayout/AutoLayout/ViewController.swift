//
//  ViewController.swift
//  AutoLayout
//
//  Created by larryhou on 3/21/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		updateConstraints()
	}

	func updateConstraints() {
		var label = view.viewWithTag(1)! as UILabel
		label.font = UIFont.systemFontOfSize(16)
		label.text = "Created By Visual Format Language"
		label.removeFromSuperview()

		label.setTranslatesAutoresizingMaskIntoConstraints(false)
		view.addSubview(label)

		var map: [NSObject: AnyObject] = [:]
		map.updateValue(label, forKey: "label")

		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[label]-|", options: NSLayoutFormatOptions(0), metrics: nil, views: map))
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[label(30)]-20-|", options: NSLayoutFormatOptions(0), metrics: nil, views: map))

		var pad1 = UIView()
		pad1.setTranslatesAutoresizingMaskIntoConstraints(false)
		pad1.backgroundColor = UIColor.blueColor()
		map.updateValue(pad1, forKey: "pad1")
		view.addSubview(pad1)
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[pad1(1)]", options: NSLayoutFormatOptions(0), metrics: nil, views: map))

		var pad2 = UIView()
		pad2.setTranslatesAutoresizingMaskIntoConstraints(false)
		map.updateValue(pad2, forKey: "pad2")
		view.addSubview(pad2)
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[pad2(1)]", options: NSLayoutFormatOptions(0), metrics: nil, views: map))

		var name = UILabel()
		name.text = "LARRY HOU"
		name.font = UIFont.systemFontOfSize(30)
		name.textAlignment = NSTextAlignment.Center
		name.setTranslatesAutoresizingMaskIntoConstraints(false)
		view.addSubview(name)

		map.updateValue(name, forKey: "name")
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[name]-|", options: NSLayoutFormatOptions(0), metrics: nil, views: map))
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[pad1]-[name(30)]-[pad2(==pad1)]|", options: NSLayoutFormatOptions(0), metrics: nil, views: map))
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

}
