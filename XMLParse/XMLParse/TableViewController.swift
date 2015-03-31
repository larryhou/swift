//
//  ViewController.swift
//  XMLParse
//
//  Created by larryhou on 3/27/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

func getpt<T>(inout target:T)->UnsafeMutablePointer<T>
{
	return withUnsafeMutablePointer(&target, {$0})
}

class MusicAlbumCell:UITableViewCell
{
	@IBOutlet weak var artist: UILabel!
	@IBOutlet weak var albumName: UILabel!
	@IBOutlet weak var albumCover: UIImageView!
	@IBOutlet weak var albumPrice: UILabel!
	var task:NSURLSessionDownloadTask!
}


class TableViewController: UITableViewController, UITableViewDataSource, XMLReaderDelegate
{
	private var _data:NSArray!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		_data = NSArray()
		
		downloadRSSXML()
	}
	
	//MARK: download rss xml
	func downloadRSSXML()
	{
		let url = NSURL(string: "http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wpa/MRSS/newreleases/limit=300/rss.xml")!
		NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: url), completionHandler:
		{
			(data:NSData!, response:NSURLResponse!, error:NSError!) in
			if error == nil
			{
				println(response)
				XMLReader().read(data, delegate: self)
			}
			else
			{
				println(error)
			}
		}).resume()
	}
	
	func readerDidFinishDocument(reader: XMLReader, data: NSDictionary, elapse: NSTimeInterval)
	{
		_data = data.valueForKeyPath("rss.channel.item")! as NSArray
		dispatch_async(dispatch_get_main_queue(),
		{
			self.tableView.reloadData()
		})
		
		println("elapse: \(elapse)")
	}
	
	//MARK: data
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
	{
		return 110
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return _data.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		var cell = tableView.dequeueReusableCellWithIdentifier("MusicAlbumCell")! as MusicAlbumCell
		if cell.task != nil
		{
			cell.task.cancel()
		}
		
		let item = _data[indexPath.row] as NSDictionary
		let path = item.valueForKeyPath("itms:coverArt")?[2]?["$"] as String
		
		cell.albumCover.image = UIImage(named: "cover.jpg")
		
		let request = NSURLRequest(URL: NSURL(string: path)!)
		let task = NSURLSession.sharedSession().downloadTaskWithRequest(request)
		{
			(url:NSURL!, response:NSURLResponse!, error:NSError!) in
			if error == nil
			{
				let image = UIImage(data: NSData(contentsOfURL: url)!)
				dispatch_async(dispatch_get_main_queue(),
				{
					cell.albumCover.image = image
				})
			}
			
			cell.task = nil
		}
		
		cell.task = task
		task.resume()
		
		cell.albumName.text = (item.valueForKeyPath("itms:album.$") as String)
		cell.albumPrice.text = (item.valueForKeyPath("itms:albumPrice.$") as String)
		cell.artist.text = (item.valueForKeyPath("itms:artist.$") as String)
		
		return cell
		
	}
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
}

