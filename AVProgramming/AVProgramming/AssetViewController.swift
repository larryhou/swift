//
//  AssetViewController.swift
//  AVProgramming
//
//  Created by larryhou on 4/3/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import MapKit
import Foundation
import AssetsLibrary
import UIKit

class AssetAnnotation:NSObject, MKAnnotation
{
	var coordinate:CLLocationCoordinate2D
	var title:String
	
	init(coordinate:CLLocationCoordinate2D)
	{
		self.coordinate = coordinate
		self.title = NSString(format:"%.4f°/%.4f°", coordinate.latitude, coordinate.latitude);
	}
}

class AssetViewController:UIViewController, UIScrollViewDelegate, MKMapViewDelegate
{
	var url:NSURL!
	var index:Int!
	
	@IBOutlet weak var container: UIView!
	private let BAR_HEIGHT:CGFloat = 64
	
	private var _map:MKMapView!
	private var _photo:UIImageView!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		let bounds = UIScreen.mainScreen().bounds
		
		let view:UIScrollView = self.view as UIScrollView
		
		_map = MKMapView(frame: CGRectMake(0, bounds.height, bounds.width, bounds.width))
		_map.userInteractionEnabled = true
		_map.delegate = self
		container.addSubview(_map)
		
		_photo = UIImageView(frame: CGRectMake(0, 0, bounds.width, bounds.height - BAR_HEIGHT))
		container.addSubview(_photo)
		
		ALAssetsLibrary().groupForURL(url, resultBlock:
		{ (group:ALAssetsGroup!) -> Void in
		
			group.enumerateAssetsAtIndexes(NSIndexSet(index: self.index), options: NSEnumerationOptions.Concurrent, usingBlock:
			{ (asset:ALAsset!, index:Int, flag:UnsafeMutablePointer<ObjCBool>) -> Void in
				
				if asset == nil
				{
					return
				}
				
				let repr = asset.defaultRepresentation()
				let data = repr.fullScreenImage().takeUnretainedValue()
				
				let bounds = UIScreen.mainScreen().bounds
				let scale = max(CGFloat(CGImageGetWidth(data)) / bounds.width, CGFloat(CGImageGetHeight(data)) / bounds.height)
				
				let image = UIImage(CGImage: data, scale:scale,orientation:UIImageOrientation.Up)!
				
				let location = asset.valueForProperty(ALAssetPropertyLocation) as? CLLocation
				dispatch_async(dispatch_get_main_queue())
				{
					if location != nil
					{
						self._map.centerCoordinate = location!.coordinate
						self._map.setRegion(MKCoordinateRegionMakeWithDistance(location!.coordinate, 1000, 1000), animated: true)
						
						let annotation = AssetAnnotation(coordinate: location!.coordinate)
						self._map.addAnnotation(annotation)
					}
					
					var frame = self._photo.frame
					frame.size = image.size
					
					self._photo.frame = frame
					self._photo.image = image
					
					frame = self._map.frame
					frame.origin.y = self._photo.frame.origin.y + self._photo.frame.height + 5
					self._map.frame = frame
					
					var size = view.contentSize
					size.height = frame.origin.y + frame.height
					view.contentSize = size
				}
			})
		})
		{ (error:NSError!) -> Void in
			println(error)
		}
	}
	
	func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView?
	{
		return container
	}
	
	//MARK: MKAnnotation
	
	func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView!
	{
		if annotation.isKindOfClass(AssetAnnotation)
		{
			let ASSET_REUSE = "AssetAnnotationView"
			var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(ASSET_REUSE) as? MKPinAnnotationView
			if anView == nil
			{
				anView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: ASSET_REUSE)
				anView?.canShowCallout = true
			}
			
			anView!.annotation = annotation
			anView!.selected = true
			return anView!
		}
		
		return nil
	}
	
	func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!)
	{
		let anView = views.first as MKPinAnnotationView
		anView.setSelected(true, animated: true)
	}
	
}
