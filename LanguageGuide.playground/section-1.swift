// Playground - noun: a place where people can play

import Foundation


func stopUpdatingLocation()
{
	println(rand())
}

var delay:NSTimeInterval = 0.5
var timer = NSTimer.scheduledTimerWithTimeInterval(delay,
	target: nil, selector: "stopUpdatingLocation",
	userInfo: nil,
	repeats: true)
