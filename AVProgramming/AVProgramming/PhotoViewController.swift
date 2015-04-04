//
//  PhotoViewController.swift
//  AVProgramming
//
//  Created by larryhou on 4/3/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit
import Foundation
import AssetsLibrary
import CoreLocation

class PhotoCell:UITableViewCell
{
	@IBOutlet weak var thumbnail: UIImageView!
	@IBOutlet weak var location: UILabel!
	@IBOutlet weak var date: UILabel!
	@IBOutlet weak var detail: UILabel!
	
	var representation:ALAssetRepresentation!
}

class PhotoViewController: UITableViewController, UITableViewDataSource
{
	var url:NSURL!
	private var _numOfAssets:Int = 0
	private var _library:ALAssetsLibrary!
	private var _dateFormatter:NSDateFormatter!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		tableView.separatorColor = UIColor(white: SEPARATOR_COLOR_WHITE, alpha: 1.0)
		
		_dateFormatter = NSDateFormatter()
		_dateFormatter.dateFormat = "YYYY/mm/dd HH:MM:ss"
		
		_library = ALAssetsLibrary()
		_library.groupForURL(url, resultBlock:
		{ (group:ALAssetsGroup!) -> Void in
			self._numOfAssets = group.numberOfAssets()
			dispatch_async(dispatch_get_main_queue())
			{
				self.tableView.reloadData()
			}
		})
		{ (error:NSError!) -> Void in
			println(error)
		}
	}
	
	//MARK: table view
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
	{
		return 90
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return _numOfAssets
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCellWithIdentifier("PhotoCell") as PhotoCell
		let row = (_numOfAssets - 1) - indexPath.row
		
		_library.groupForURL(url, resultBlock:
		{ (group:ALAssetsGroup!) -> Void in
			
			group.enumerateAssetsAtIndexes(NSIndexSet(index: row), options: NSEnumerationOptions.Concurrent, usingBlock:
			{ (asset:ALAsset!, index:Int, flag:UnsafeMutablePointer<ObjCBool>) -> Void in
				
				if asset == nil
				{
					return
				}
				
				let image = UIImage(CGImage: asset.thumbnail().takeUnretainedValue())
				
				let repr = asset.defaultRepresentation()
				let date = asset.valueForProperty(ALAssetPropertyDate) as NSDate
				let location = asset.valueForProperty(ALAssetPropertyLocation) as? CLLocation
				let dimensions = repr.dimensions()
				
				var desc = "\(Int(dimensions.width))×\(Int(dimensions.height))"
				
				let type = asset.valueForProperty(ALAssetPropertyType) as String
				if type == ALAssetTypeVideo
				{
					let duration = asset.valueForProperty(ALAssetPropertyDuration) as Double
					let minutes = floor(duration / 60)
					let seconds = duration % 60
					
					desc += NSString(format:" %02d:%06.3f", Int(minutes), seconds) as String
				}
				
				dispatch_async(dispatch_get_main_queue())
				{
					cell.thumbnail.image = image
					cell.date.text = self._dateFormatter.stringFromDate(date)
					if location != nil
					{
						cell.location.text = NSString(format:"%.4f°/%.4f°", location!.coordinate.latitude, location!.coordinate.longitude)
						self.geocode(location!, label: cell.location)
					}
					else
					{
						cell.location.text = "Unknown Placemark"
					}
					
					cell.detail.text = desc
					
				}
			})
		})
		{ (error:NSError!) -> Void in
			println(error)
		}
		return cell
	}
	
	func geocode(location:CLLocation, label:UILabel)
	{
		var query = CLGeocoder()
		query.reverseGeocodeLocation(location, completionHandler:
		{ (result:[AnyObject]!, error:NSError!) -> Void in
			if error == nil && result.count > 0
			{
				let placemark = result.first as CLPlacemark
				let text = (placemark.addressDictionary["FormattedAddressLines"] as NSArray)[0] as String
				dispatch_async(dispatch_get_main_queue())
				{
					label.text = text
				}
			}
		})
	}
	
	//MARK: segue
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		if segue.identifier == "showAsset"
		{
			let indexPath = tableView.indexPathForSelectedRow()!
			let row = (_numOfAssets - 1) - indexPath.row
			
			var dst = segue.destinationViewController as AssetViewController
			dst.index = row
			dst.url = url
			
			tableView.deselectRowAtIndexPath(indexPath, animated: false)
		}
	}
}