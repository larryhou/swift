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
	private var zoomView:UIImageView!
	private var scroll:UIScrollView!
	
	var dirty:Bool = true
	var dataIndex:Int = -1
	var image:UIImage!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
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
		if zoomView != nil
		{
			zoomView.removeFromSuperview()
			zoomView = nil
		}
		
		zoomView = UIImageView(image: image)
		scroll.addSubview(zoomView)
		scroll.zoomScale = 0.01
		
		repairImageZoom(useAnimation: true)
		alignImageAtCenter()
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
		alignImageAtCenter()
		repairImageZoom()
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