//
//  ViewController.swift
//  UIScrollView
//
//  Created by larryhou on 3/16/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate
{
	private let MAXIMUM_SCALE:CGFloat = 0.5
	
	private var zoomView:UIImageView!

	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		var view = self.view as UIScrollView
		view.contentSize = CGSize(width: 320, height: 568)
		view.minimumZoomScale = 0.01
		view.maximumZoomScale = 2.00
		view.delegate = self
		view.pinchGestureRecognizer.addTarget(self, action: "pinchUpdated:")
		
		zoomView = UIImageView(image: UIImage(named: "4.jpg"))
		zoomView.userInteractionEnabled = false
		view.addSubview(zoomView)
		
		view.zoomScale = view.minimumZoomScale
		repairImageZoom()
		
		UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged:", name: UIDeviceOrientationDidChangeNotification, object: nil)
		
		var tap = UITapGestureRecognizer()
		tap.numberOfTapsRequired = 2
		tap.addTarget(self, action: "smartZoomImage:")
		view.addGestureRecognizer(tap)
	}
	
	func orientationChanged(notification:NSNotification)
	{
		alignImageAtCenter()
		repairImageZoom()
	}
	
	func smartZoomImage(gesture:UITapGestureRecognizer)
	{
		let view = self.view as UIScrollView
		let MINIMUM_SCALE:CGFloat = view.frame.width / (zoomView.frame.width / view.zoomScale)
		
		var scale:CGFloat!
		if view.zoomScale > MINIMUM_SCALE + 0.0001
		{
			scale = MINIMUM_SCALE
		}
		else
		{
			scale = MAXIMUM_SCALE
		}
		
		if scale != nil
		{
			view.setZoomScale(scale, animated: true)
		}
	}
	
	func pinchUpdated(gesture:UIPinchGestureRecognizer)
	{
		let view = self.view as UIScrollView
		
		switch gesture.state
		{
			case .Began:
				view.panGestureRecognizer.enabled = false
				break
			
			case .Ended:
				view.panGestureRecognizer.enabled = true
				repairImageZoom()
				break
			
			default:break
		}
	}
	
	func repairImageZoom()
	{
		let view = self.view as UIScrollView
		let MINIMUM_SCALE:CGFloat = view.frame.width / (zoomView.frame.width / view.zoomScale)
		
		var scale:CGFloat!
		if view.zoomScale < MINIMUM_SCALE
		{
			scale = MINIMUM_SCALE
		}
		else
		if view.zoomScale > MAXIMUM_SCALE
		{
			scale = MAXIMUM_SCALE
		}
		
		if scale != nil
		{
			view.setZoomScale(scale, animated: true)
		}
	}
	
	func alignImageAtCenter()
	{
		var view = self.view as UIScrollView
		var inset = UIEdgeInsetsMake(0, 0, 0, 0)
		
		var frame = zoomView.frame
		if frame.width < view.frame.width
		{
			inset.left = (view.frame.width - frame.width) / 2.0
		}
		else
		{
			inset.left = 0.0
		}
		
		if frame.height < view.frame.height
		{
			inset.top = (view.frame.height - frame.height) / 2.0
		}
		else
		{
			inset.top = 0.0
		}
		
		view.contentInset = inset
	}
	
	func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView?
	{
		return zoomView
	}
	
	func scrollViewDidZoom(scrollView: UIScrollView)
	{
		alignImageAtCenter()
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
}

