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
	var dataIndex:Int = 0
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		var view:UIScrollView = UIScrollView()
		view.frame = UIScreen.mainScreen().applicationFrame;
		view.contentSize = view.frame.size
		view.minimumZoomScale = 0.01
		view.maximumZoomScale = 2.00
		self.view = view
		
		zoomView = UIImageView()
		view.addSubview(zoomView)
		
		view.pinchGestureRecognizer.addTarget(self, action: "pinchUpdated:")
	}
	
	func pinchUpdated(gesture:UIPinchGestureRecognizer)
	{
		let view = self.view as UIScrollView
		
		switch gesture.state
		{
			case .Began:
				view.panGestureRecognizer.enabled = false
			
			case .Ended:
				view.panGestureRecognizer.enabled = true
				repairImageZoom()
			
			default:break
		}
	}
	
	func setImage(image:UIImage, dataIndex index:Int)
	{
		self.zoomView.image = image
		self.dataIndex = index
		
		alignImageAtCenter()
		repairImageZoom()
	}
	
	func repairImageZoom()
	{
		let view = self.view as UIScrollView
		let MAX_SIZE_W = zoomView.frame.width / view.zoomScale
		
		var scale:CGFloat!
		if zoomView.frame.width < view.frame.width + 0.0001
		{
			scale = view.frame.width / MAX_SIZE_W
		}
		else
		if zoomView.frame.width > (MAX_SIZE_W / UIScreen.mainScreen().scale)
		{
			scale = 1.0 / UIScreen.mainScreen().scale
		}
		
		if scale != nil
		{
			view.setZoomScale(scale, animated: true)
		}
	}
	
	func alignImageAtCenter()
	{
		let view = self.view as UIScrollView
		
		var inset = UIEdgeInsetsMake(0, 0, 0, 0)
		if zoomView.frame.width < view.frame.width
		{
			inset.left = (view.frame.width - zoomView.frame.width) / 2.0
		}
		else
		{
			inset.left = 0.0
		}
		
		if zoomView.frame.height < view.frame.height
		{
			inset.top = (view.frame.height - zoomView.frame.height) / 2.0
		}
		else
		{
			inset.top = 0.0
		}
		
		view.contentInset = inset
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
		let view = self.view as UIScrollView
		view.pinchGestureRecognizer.removeObserver(self, forKeyPath: "pinchUpdated:")
	}
}