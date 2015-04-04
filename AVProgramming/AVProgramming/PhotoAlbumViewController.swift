//
//  ViewController.swift
//  AVProgramming
//
//  Created by larryhou on 4/3/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit
import AssetsLibrary
import CoreGraphics

let SEPARATOR_COLOR_WHITE:CGFloat = 0.9

class PhotoAlbumCell: UITableViewCell
{
	@IBOutlet weak var posterImage: UIImageView!
	@IBOutlet weak var albumName: UILabel!
	@IBOutlet weak var albumAssetsCount: UILabel!
	@IBOutlet weak var albumID: UILabel!
}

class NavigationViewController:UINavigationController
{
	override func shouldAutorotate() -> Bool
	{
		return topViewController.shouldAutorotate()
	}
	
	override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation
	{
		return topViewController.preferredInterfaceOrientationForPresentation()
	}
}

class PhotoAlubmViewController: UITableViewController, UITableViewDataSource
{
	private var _groups:[NSURL]!
	private var _library:ALAssetsLibrary!

	override func viewDidLoad()
	{
		super.viewDidLoad()
		tableView.separatorColor = UIColor(white: SEPARATOR_COLOR_WHITE, alpha: 1.0)
		
		_groups = []
		
		_library = ALAssetsLibrary()
		_library.enumerateGroupsWithTypes(ALAssetsGroupAlbum | ALAssetsGroupSavedPhotos, usingBlock:
		{
			(group:ALAssetsGroup!, stop:UnsafeMutablePointer<ObjCBool>) in
			if group != nil
			{
				self._groups.append(group.valueForProperty(ALAssetsGroupPropertyURL) as NSURL)
				dispatch_async(dispatch_get_main_queue())
				{
					self.tableView.reloadData()
				}
			}
			
		}, failureBlock:
		{
			(error:NSError!) in
			println(error)
		})

	}
	
	//MARK: table view
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
	{
		return 90
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return _groups.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let url = _groups[indexPath.row]
		let cell = tableView.dequeueReusableCellWithIdentifier("PhotoAlbumCell") as PhotoAlbumCell
		_library.groupForURL(url, resultBlock:
		{
			(group:ALAssetsGroup!) in
			cell.albumName.text = (group.valueForProperty(ALAssetsGroupPropertyName) as String)
			cell.albumID.text = (group.valueForProperty(ALAssetsGroupPropertyPersistentID) as String)
			cell.albumAssetsCount.text = "\(group.numberOfAssets())"
			cell.posterImage.image = UIImage(CGImage: group.posterImage().takeUnretainedValue(), scale: UIScreen.mainScreen().scale, orientation: UIImageOrientation.Up)
			
		}, failureBlock:
		{
			(error:NSError!) in
			println((error, url.absoluteString))
		})

		return cell
	}
	
	//MARK: segue
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		if segue.identifier == "showAlbumPhotos"
		{
			let indexPath = tableView.indexPathForSelectedRow()!
			
			var dst = segue.destinationViewController as PhotoViewController
			dst.url = _groups[indexPath.row]
			
			tableView.deselectRowAtIndexPath(indexPath, animated: false)
		}
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

}

