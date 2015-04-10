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

class MapPinAnnotation:NSObject, MKAnnotation
{
	dynamic var coordinate:CLLocationCoordinate2D
	dynamic var title:String
	dynamic var subtitle:String
	
	init(coordinate:CLLocationCoordinate2D)
	{
		self.coordinate = coordinate
		
		self.title = ""
		self.subtitle = String(format:"纬:%.4f° 经:%.4f°", coordinate.latitude, coordinate.latitude);
	}
}

class AssetViewController:UIViewController, UIScrollViewDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate
{
	var url:NSURL!
	var index:Int!
	
	@IBOutlet weak var container: UIView!
	private let BAR_HEIGHT:CGFloat = 64
	private let MAP_REGION_SPAN:CLLocationDistance = 500
	
	private var _map:MKMapView!
	private var _photo:UIImageView!
	private var _tap:UILongPressGestureRecognizer!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		let bounds = UIScreen.mainScreen().bounds
		
		let view:UIScrollView = self.view as! UIScrollView
		
		_map = MKMapView(frame: CGRectMake(0, bounds.height, bounds.width, bounds.width))
		_map.userInteractionEnabled = true
		_map.delegate = self
		view.addSubview(_map)
		
		_photo = UIImageView(frame: CGRectMake(0, 0, bounds.width, bounds.height - BAR_HEIGHT))
		view.addSubview(_photo)
		
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
				let type = asset.valueForProperty(ALAssetPropertyType) as! String
				
				let bounds = UIScreen.mainScreen().bounds
				let scale = max(CGFloat(CGImageGetWidth(data)) / bounds.width, CGFloat(CGImageGetHeight(data)) / bounds.height)
				
				let image = UIImage(CGImage: data, scale:scale,orientation:UIImageOrientation.Up)!
				
				let location = asset.valueForProperty(ALAssetPropertyLocation) as? CLLocation
				dispatch_async(dispatch_get_main_queue())
				{
					if location != nil && location!.coordinate.latitude != -180 && location!.coordinate.longitude != -80
					{
						self._map.centerCoordinate = location!.coordinate
						self._map.setRegion(MKCoordinateRegionMakeWithDistance(location!.coordinate,
							self.MAP_REGION_SPAN, self.MAP_REGION_SPAN), animated: true)
						
						let annotation = MapPinAnnotation(coordinate: location!.coordinate)
						self._map.addAnnotation(annotation)
					}
					
					var frame = CGRectZero
					if type == ALAssetTypePhoto
					{
						frame = self._photo.frame
						frame.size = image.size
						
						self._photo.image = image
					}
					
					self._photo.frame = frame
					
					frame = self._map.frame
					frame.origin.y = self._photo.frame.origin.y + self._photo.frame.height + 5
					self._map.frame = frame
					
					var size = view.contentSize
					size.height = frame.origin.y + frame.height
					view.contentSize = size
				}
				
				self.trace(repr)
			})
		})
		{ (error:NSError!) -> Void in
			println(error)
		}
		
		_tap = UILongPressGestureRecognizer()
		_tap.minimumPressDuration = 0.5
		_tap.addTarget(self, action: "moveAnnotationInView:")
		view.addGestureRecognizer(_tap)
	}
	
	func trace(representation:ALAssetRepresentation)
	{
		println("------------------------------")
		println(representation.url().absoluteString)
		println(representation.UTI())
		for (key, value) in representation.metadata()
		{
			println((key, value))
		}
	}
	
	func moveAnnotationInView(guesture:UILongPressGestureRecognizer)
	{
		let annotation = _map.annotations.first as! MapPinAnnotation
		
		_map.setRegion(MKCoordinateRegionMakeWithDistance(annotation.coordinate, MAP_REGION_SPAN, MAP_REGION_SPAN), animated: true)
		_map.selectAnnotation(annotation, animated: true)
		_map.userInteractionEnabled = false
	}
	
	func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView?
	{
		return nil
	}
	
	func scrollViewDidScroll(scrollView: UIScrollView)
	{
		_map.userInteractionEnabled = true
	}
	
	override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
	{
		println(size)
		
		var frame = _photo.frame
		if _photo.image != nil
		{
			var scale = size.width / frame.width
			frame.size.height *= scale
			frame.size.width *= scale
			_photo.frame = frame
		}
		
		frame = _map.frame
		frame.size = CGSizeMake(size.width, size.width)
		frame.origin.y = _photo.frame.height + 5
		_map.frame = frame
		
		(view as! UIScrollView).contentSize = CGSizeMake(size.width, frame.origin.y + frame.height)
	}
	
	//MARK: Map Annotation
	
	func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView!
	{
		if annotation.isKindOfClass(MapPinAnnotation)
		{
			let REUSE_IDENTIFIER = "AlbumAssetAnnotation"
			var view = mapView.dequeueReusableAnnotationViewWithIdentifier(REUSE_IDENTIFIER) as? MKPinAnnotationView
			if view == nil
			{
				view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: REUSE_IDENTIFIER)
				view!.canShowCallout = true
				view!.animatesDrop = true
			}
			
			view!.annotation = annotation
			view!.selected = true
			return view!
		}
		
		return nil
	}
	
	func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!)
	{
		var view = views.first as! MKPinAnnotationView
		let coordinate = view.annotation.coordinate
		
		_map.selectAnnotation(view.annotation, animated: true)
		
		CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
		{ (result:[AnyObject]!, error:NSError!) in
				
			if result != nil && result.count > 0
			{
				let placemark = result.first as! CLPlacemark
				let title = (placemark.addressDictionary["FormattedAddressLines"] as! [String])[0]
				dispatch_async(dispatch_get_main_queue())
				{
					(view.annotation as! MapPinAnnotation).title = title
				}
			}
		}
	}
	
	deinit
	{
		_tap.removeTarget(self, action: "moveAnnotationInView:")
	}
}
