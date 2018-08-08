//
//  ViewController.swift
//  Teslameter
//
//  Created by larryhou on 9/18/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
	@IBOutlet var magnitude: UILabel!
	@IBOutlet var graph: TeslaGraphView!

	@IBOutlet var teslaX: UILabel!
	@IBOutlet var teslaY: UILabel!
	@IBOutlet var teslaZ: UILabel!

	private var attrX: [NSObject: AnyObject]!
	private var attrY: [NSObject: AnyObject]!
	private var attrZ: [NSObject: AnyObject]!
	private var positiveAttr: [NSObject: AnyObject]!
	private var nagitiveAttr: [NSObject: AnyObject]!

	private var locationManager: CLLocationManager!
	private var timestamp: NSDate!

	override func viewDidLoad() {
		super.viewDidLoad()

		attrX = [NSForegroundColorAttributeName: UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)]
		attrY = [NSForegroundColorAttributeName: UIColor.greenColor()]
		attrZ = [NSForegroundColorAttributeName: UIColor.blueColor()]

		positiveAttr = [NSForegroundColorAttributeName: UIColor.blackColor()]
		nagitiveAttr = [NSForegroundColorAttributeName: UIColor.redColor()]

		locationManager = CLLocationManager()
		locationManager.requestWhenInUseAuthorization()
		locationManager.headingFilter = kCLHeadingFilterNone
		locationManager.delegate = self

		locationManager.startUpdatingHeading()
	}

	private func setAttributedText(#label:UILabel, title: String, style: [NSObject: AnyObject], value: Double) {
		var text = NSMutableAttributedString(string: title, attributes: style)
		var attr = value > 0 ? positiveAttr : nagitiveAttr

		text.appendAttributedString(NSAttributedString(string: String(format: "%.1f", fabs(value)), attributes: attr))
		label.attributedText = text
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: 罗盘定位
	func locationManager(manager: CLLocationManager!, didUpdateHeading newHeading: CLHeading!) {
		var mag = sqrt(newHeading.x * newHeading.x + newHeading.y * newHeading.y * newHeading.z * newHeading.z)
		magnitude.text = String(format: "%.1f", mag)

		graph.insertHeadingTesla(x: newHeading.x, y: newHeading.y, z: newHeading.z)

		setAttributedText(label: teslaX, title: "Xμ: ", style: attrX, value: newHeading.x)
		setAttributedText(label: teslaY, title: "Yμ: ", style: attrY, value: newHeading.y)
		setAttributedText(label: teslaZ, title: "Zμ: ", style: attrZ, value: newHeading.z)

		if timestamp == nil || newHeading.timestamp.timeIntervalSinceDate(timestamp) > 1 {
			timestamp = newHeading.timestamp
			//println(timestamp)
		}
	}

	func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
		println(error)
	}
}
