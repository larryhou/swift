// Playground - noun: a place where people can play

import Foundation

rand()

var formatter = NSNumberFormatter()
formatter.minimumFractionDigits = 2
formatter.minimumIntegerDigits = 1

formatter.respondsToSelector(Selector("setMinumFractionDigits:"))
