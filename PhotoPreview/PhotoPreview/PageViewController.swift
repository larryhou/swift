//
//  ViewController.swift
//  PhotoPreview
//
//  Created by larryhou on 3/19/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

class PageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
	let PHOTO_COUNT = 4
	
	private var recycle:[PhotoPreviewController]!
	private var dataIndex:Int = 0
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		dataSource = self
		delegate = self
		
		recycle = []
		for i in 0..<3
		{
			recycle.append(PhotoPreviewController())
		}
		
		dataIndex = 0
		setViewControllers([getPreviewController(dataIndex: dataIndex)], direction: .Forward, animated: false, completion: nil)
	}
	
	func getPreviewController(dataIndex index:Int)->PhotoPreviewController
	{
		let viewIndex = index % 3
		recycle[viewIndex].setImage(UIImage(named: "\(index + 1).jpg")!, dataIndex: index)
		return recycle[viewIndex]
	}
	
	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
	{
		let current = viewController as PhotoPreviewController
		if current.dataIndex + 1 < PHOTO_COUNT
		{
			dataIndex = current.dataIndex + 1
			return getPreviewController(dataIndex: dataIndex)
		}
		
		return nil
	}
	
	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
	{
		let current = viewController as PhotoPreviewController
		if current.dataIndex > 0
		{
			dataIndex = current.dataIndex - 1
			return getPreviewController(dataIndex: dataIndex)
		}
		
		return nil
	}
	
	func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int
	{
		return PHOTO_COUNT
	}
	
	func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int
	{
		return dataIndex
	}
	
	//MARK: reset state
	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool)
	{
		var prev = previousViewControllers.first! as PhotoPreviewController
		prev.dirty = true
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
}