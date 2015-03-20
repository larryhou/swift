//
//  PhotoPreviewController.swift
//  PhotoPreview
//
//  Created by larryhou on 3/19/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import Foundation
import UIKit

class PhotoPreviewController:UIViewController, UIScrollViewDelegate
{
	private var background:UIImageView!
	private var zoomView:UIImageView!
	private var scroll:UIScrollView!
	
	var dirty:Bool = true
	var dataIndex:Int = -1
	var image:UIImage!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		view.clipsToBounds = true
		
		scroll = UIScrollView()
		scroll.frame = UIScreen.mainScreen().applicationFrame;
		scroll.contentSize = scroll.frame.size
		scroll.minimumZoomScale = 0.01
		scroll.maximumZoomScale = 2.00
		scroll.delegate = self
		view.addSubview(scroll)
		
		scroll.pinchGestureRecognizer.addTarget(self, action: "pinchUpdated:")
		
		var tap = UITapGestureRecognizer()
		tap.numberOfTapsRequired = 2
		tap.addTarget(self, action: "doubleTapZoom:")
		scroll.addGestureRecognizer(tap)
	}
	
	override func viewWillAppear(animated: Bool)
	{
		if !dirty
		{
			return
		}
		
		dirty = false
		if zoomView != nil && zoomView.superview != nil
		{
			zoomView.removeFromSuperview()
		}
		
		zoomView = UIImageView(image: image)
		scroll.addSubview(zoomView)
		
		if background != nil && background.superview != nil
		{
			background.removeFromSuperview()
		}
		
		background = UIImageView(image: createBackgroundImage(inputImage: image))
		view.insertSubview(background, atIndex: 0)
		
		var frame = background.frame
		frame.origin.x = (view.frame.width - frame.width) / 2.0
		frame.origin.y = (view.frame.height - frame.height) / 2.0
		background.frame = frame
		
		scroll.zoomScale = 0.01
		
		repairImageZoom(useAnimation: true)
		alignImageAtCenter()
	}
	
	func createBackgroundImage(inputImage input:UIImage)->UIImage?
	{
		let bounds = UIScreen.mainScreen().bounds
		let size = CGSizeMake(bounds.width / 2.0, bounds.height / 2.0)
		
		let scale = max(size.width / input.size.width, size.height / input.size.height)
		
		UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
		let context = UIGraphicsGetCurrentContext()
		
		CGContextScaleCTM(context, scale, scale)
		
		let tx = (size.width / scale - input.size.width) / 2.0
		let ty = (size.height / scale - input.size.height) / 2.0
		CGContextTranslateCTM(context, tx, ty)
		
		input.drawAtPoint(CGPointMake(0, 0))
		
		var data:UIImage = UIGraphicsGetImageFromCurrentImageContext()!

		UIGraphicsEndImageContext()
		
		var filter = CIFilter(name: "CIGaussianBlur")
		filter.setValue(CIImage(image: data), forKey: kCIInputImageKey)
		filter.setValue(20.0, forKey: kCIInputRadiusKey)
		return UIImage(CIImage: filter.outputImage)
	}
	
	func doubleTapZoom(gesture:UITapGestureRecognizer)
	{
		let MAX_SIZE_W = zoomView.frame.width / scroll.zoomScale
		
		var scale:CGFloat
		if zoomView.frame.width > scroll.frame.width + 0.0001
		{
			scale = scroll.frame.width / MAX_SIZE_W
		}
		else
		{
			scale = 1.0 / UIScreen.mainScreen().scale
		}
		
		scroll.setZoomScale(scale, animated: true)
	}
	
	func pinchUpdated(gesture:UIPinchGestureRecognizer)
	{
		switch gesture.state
		{
			case .Began:
				scroll.panGestureRecognizer.enabled = false
			
			case .Ended:
				scroll.panGestureRecognizer.enabled = true
				repairImageZoom()
			
			default:break
		}
	}
	
	func setImage(image:UIImage, dataIndex index:Int)
	{
		self.dirty = true
		
		self.dataIndex = index
		self.image = image
	}
	
	func restoreImageZoom()
	{
		let MAX_SIZE_W = zoomView.frame.width / scroll.zoomScale
		
		scroll.zoomScale = scroll.frame.width / MAX_SIZE_W
	}
	
	func repairImageZoom(useAnimation flag:Bool = true)
	{
		let MAX_SIZE_W = zoomView.frame.width / scroll.zoomScale
		
		var scale:CGFloat!
		if zoomView.frame.width < scroll.frame.width
		{
			scale = scroll.frame.width / MAX_SIZE_W
		}
		else
		if zoomView.frame.width > (MAX_SIZE_W / UIScreen.mainScreen().scale)
		{
			scale = 1.0 / UIScreen.mainScreen().scale
		}
		
		if scale != nil
		{
			if flag
			{
				scroll.setZoomScale(scale, animated: true)
			}
			else
			{
				scroll.zoomScale = scale
			}
		}
	}
	
	func alignImageAtCenter()
	{
		var inset = UIEdgeInsetsMake(0, 0, 0, 0)
		if zoomView.frame.width < scroll.frame.width
		{
			inset.left = (scroll.frame.width - zoomView.frame.width) / 2.0
		}
		else
		{
			inset.left = 0.0
		}
		
		if zoomView.frame.height < scroll.frame.height
		{
			inset.top = (scroll.frame.height - zoomView.frame.height) / 2.0
		}
		else
		{
			inset.top = 0.0
		}
		
		scroll.contentInset = inset
	}
	
	func scrollViewDidZoom(scrollView: UIScrollView)
	{
		alignImageAtCenter()
	}
	
	override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation)
	{
		repairImageZoom()
		alignImageAtCenter()
	}
	
	func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView?
	{
		return zoomView
	}
	
	deinit
	{
		scroll.pinchGestureRecognizer.removeObserver(self, forKeyPath: "pinchUpdated:")
	}
}