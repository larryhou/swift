//
//  ViewController.swift
//  PhotoPreview
//
//  Created by larryhou on 3/19/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

class PageViewController: UIPageViewController, UIPageViewControllerDataSource
{
	private var ctrlist:[PhotoPreviewController]!
	private var dataIndex:Int = 0
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
	}
	
	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
	{
		let current = viewController as PhotoPreviewController
		if current.dataIndex < ctrlist.count
		{
			dataIndex = current.dataIndex + 1
			return ctrlist[dataIndex]
		}
		
		return nil
	}
	
	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
	{
		let current = viewController as PhotoPreviewController
		if current.dataIndex > 0
		{
			dataIndex = current.dataIndex - 1
			return ctrlist[dataIndex]
		}
		
		return nil
	}
	
	func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int
	{
		return ctrlist.count
	}
	
	func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int
	{
		return dataIndex
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
}