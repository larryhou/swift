//
//  ViewController.swift
//  UIScrollView
//
//  Created by larryhou on 3/16/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

extension CGAffineTransform
{
	var description:String
	{
		return "{a:\(self.a), b:\(self.b), c:\(self.c), d:\(self.d), tx:\(self.tx), ty:\(self.ty)}"
	}
}

class ViewController: UIViewController, UIScrollViewDelegate
{
	private let IMG_SIZE_W:CGFloat = 3264.0
	private let IMG_SIZE_H:CGFloat = 2448.0
	
	private var imageView:UIImageView!

	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		var view = self.view as UIScrollView
		view.contentSize = CGSize(width: 320, height: 568)
		view.minimumZoomScale = 320.0/IMG_SIZE_W
		view.maximumZoomScale = 0.5
		view.delegate = self
		view.pinchGestureRecognizer.addTarget(self, action: "pinchUpdated:")
		view.addObserver(self, forKeyPath: "zoomScale", options: .New, context: &view)
		
		imageView = UIImageView(image: UIImage(named: "1.JPG"))
		imageView.layer.anchorPoint = CGPointMake(0.5, 0.5)
		view.addSubview(imageView)
		
		view.zoomScale = view.minimumZoomScale
		centerAlignImage(true)
		
		UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged:", name: UIDeviceOrientationDidChangeNotification, object: nil)
		
		var tap = UITapGestureRecognizer()
		tap.numberOfTapsRequired = 2
		tap.addTarget(self, action: "smartZoomImage:")
		view.addGestureRecognizer(tap)
	}
	
	override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>)
	{
		if context == &view
		{
			println(change[NSKeyValueChangeNewKey])
		}
		else
		if context == &imageView
		{
			println(imageView.frame)
		}
	}
	
	func smartZoomImage(gesture:UITapGestureRecognizer)
	{
		let view = self.view as UIScrollView
		
		var frame = imageView.frame
		
		var scale:CGFloat
		if frame.width / IMG_SIZE_W > view.minimumZoomScale + 0.0001
		{
			scale = view.minimumZoomScale
			frame.origin.x = (view.frame.width - IMG_SIZE_W * view.minimumZoomScale) / 2.0
			frame.origin.y = (view.frame.height - IMG_SIZE_H * view.minimumZoomScale) / 2.0
		}
		else
		{
			scale = view.maximumZoomScale
			frame.origin.x = 0
			frame.origin.y = 0
		}
		
		view.userInteractionEnabled = false
		UIView.animateWithDuration(0.5, animations:
		{
			self.imageView.frame = frame
			view.zoomScale = scale
		}, completion:
		{
			flag in
			view.userInteractionEnabled = true
		})
	}
	
	func orientationChanged(notification:NSNotification)
	{
		centerAlignImage(true)
	}
	
	func pinchUpdated(gesture:UIPinchGestureRecognizer)
	{
		let view = self.view as UIScrollView
		
		switch gesture.state
		{
			case .Changed:
				break
			
			case .Ended:
				break
			
			default:
				break
		}
	}
	
//	func centerAlignImage()
//	{
//		centerAlignImage(useAnimation: false)
//		return
//		
//		var view = self.view as UIScrollView
//		var inset = UIEdgeInsetsMake(0, 0, 0, 0)
//		
//		var frame = imageView.frame
//		if frame.width < view.frame.width
//		{
//			inset.left = (view.frame.width - frame.width) / 2.0
//		}
//		else
//		{
//			inset.left = 0.0
//		}
//		
//		if frame.height < view.frame.height
//		{
//			inset.top = (view.frame.height - frame.height) / 2.0
//		}
//		else
//		{
//			inset.top = 0.0
//		}
//		
//		view.contentInset = inset
//	}
	
	func centerAlignImage(animateChange:Bool, duration:NSTimeInterval = 0.5)
	{
		var frame = imageView.frame
		if frame.width < view.frame.width
		{
			frame.origin.x = (view.frame.width - frame.width) / 2.0
		}
		else
		{
			frame.origin.x = 0
		}
		
		if frame.height < view.frame.height
		{
			frame.origin.y = (view.frame.height - frame.height) / 2.0
		}
		else
		{
			frame.origin.y = 0
		}
		
		if animateChange
		{
			view.userInteractionEnabled = false
			UIView.animateWithDuration(duration, animations:
			{
				self.imageView.frame = frame
			}, completion:
			{
				flag in
				self.view.userInteractionEnabled = true
			})
		}
		else
		{
			imageView.frame = frame
		}
	}
	
	func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView?
	{
		return imageView
	}
	
	func scrollViewDidZoom(scrollView: UIScrollView)
	{
		centerAlignImage(true, duration:0.2)
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
}

