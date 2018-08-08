//
//  TeslaGraphView.swift
//  Teslameter
//
//  Created by larryhou on 9/18/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class TeslaGraphView: UIView {
	enum TeslaAxis: Int {
		case X
		case Y
		case Z
	}

	private let GRAPH_DENSITY = 100
	private let TICK_NUM = 4

	private var buffer: [[CLHeadingComponentValue]] = []
	private var index: Int = 0

	func insertHeadingTesla(#x:CLHeadingComponentValue, y: CLHeadingComponentValue, z: CLHeadingComponentValue) {
		if buffer.count < GRAPH_DENSITY {
			buffer.append([0.0, 0.0, 0.0])
		}

		buffer[index][TeslaAxis.X.rawValue] = x
		buffer[index][TeslaAxis.Y.rawValue] = y
		buffer[index][TeslaAxis.Z.rawValue] = z
		index = (index + 1) % GRAPH_DENSITY

		setNeedsDisplay()
	}

	private func drawGraph(#bounds:CGRect, inContext context: CGContextRef) {
		CGContextSaveGState(context)

		CGContextBeginPath(context)

		let delta = bounds.height / CGFloat( 2 * TICK_NUM)

		for i in 1..<(2 * TICK_NUM) {
			CGContextMoveToPoint(context, 0.0, delta * CGFloat(i))
			CGContextAddLineToPoint(context, bounds.width, delta * CGFloat(i))
		}

		CGContextSetLineWidth(context, 0.5)
		CGContextSetGrayStrokeColor(context, 0.75, 1.0)
		CGContextStrokePath(context)

		CGContextBeginPath(context)
		CGContextMoveToPoint(context, 0, bounds.height / 2)
		CGContextAddLineToPoint(context, bounds.width, bounds.height / 2)
		CGContextSetLineWidth(context, 0.5)
		CGContextSetGrayStrokeColor(context, 0.0, 1.0)
		CGContextStrokePath(context)

		CGContextRestoreGState(context)
	}

	private func drawTeslaBuffer(#axis:Int, fromIndex index: Int, inContext context: CGContextRef) {
		CGContextSaveGState(context)

		CGContextBeginPath(context)

		for i in 0..<buffer.count {
			var iter = (index + i) % buffer.count
			var comp: CGFloat = CGFloat(buffer[iter][axis] / 128 * 8)
			if comp > 0 {
				comp = bounds.height / 2 - fmin(comp, CGFloat(TICK_NUM)) * bounds.height / 2 / CGFloat(TICK_NUM)
			} else {
				comp = bounds.height / 2 + fmin(fabs(comp), CGFloat(TICK_NUM)) * bounds.height / 2 / CGFloat(TICK_NUM)
			}

			if i == 0 {
				CGContextMoveToPoint(context, 0, comp)
			} else {
				CGContextAddLineToPoint(context, CGFloat(i) * bounds.width / CGFloat(GRAPH_DENSITY), comp)
			}
		}

		CGContextSetLineWidth(context, 2.0)
		CGContextSetLineJoin(context, kCGLineJoinRound)
		switch TeslaAxis(rawValue: axis)! {
			case .X:CGContextSetRGBStrokeColor(context, 1.0, 0.0, 1.0, 1.0)
			case .Y:CGContextSetRGBStrokeColor(context, 0.0, 1.0, 0.0, 1.0)
			case .Z:CGContextSetRGBStrokeColor(context, 0.0, 0.0, 1.0, 1.0)
		}

		CGContextStrokePath(context)

		CGContextRestoreGState(context)
	}

	override func drawRect(rect: CGRect) {
		var context = UIGraphicsGetCurrentContext()
		var bounds = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)

		drawGraph(bounds: bounds, inContext: context)

		CGContextSetAllowsAntialiasing(context, false)

		for axis in 0..<3 {
			drawTeslaBuffer(axis: axis, fromIndex: index, inContext: context)
		}

		CGContextSetAllowsAntialiasing(context, true)
	}
}
