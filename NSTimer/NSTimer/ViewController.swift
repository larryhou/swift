//
//  ViewController.swift
//  NSTimer
//
//  Created by larryhou on 4/1/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
	private var startstamp: NSTimeInterval = 0
	private var laststamp: NSTimeInterval = 0

	override func viewDidLoad() {
		super.viewDidLoad()

		scheduleNewTimer()
	}

	func scheduleNewTimer() {
		startstamp = NSDate.timeIntervalSinceReferenceDate()
		laststamp = startstamp

		NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "tickUpdate:", userInfo: "data", repeats: true)
	}

	func tickUpdate(timer: NSTimer) {
		let now = NSDate.timeIntervalSinceReferenceDate()

		println(now - laststamp)

		laststamp = now
		if now - startstamp >= 30.0 {
			timer.invalidate()
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
