//
//  LocationDetailTableView.swift
//  LocationTraker
//
//  Created by larryhou on 28/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import MapKit
import UIKit

class PinAnnotation:NSObject, MKAnnotation
{
    dynamic var title:String?
    dynamic var subtitle:String?
    dynamic var coordinate: CLLocationCoordinate2D
    var removable = false
    
    var tintColor:UIColor?
    
    init(latitude:Double, longitude:Double)
    {
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.title = String(format: "%.7f°,%.7f°",latitude, longitude)
    }
}

class LocationDetailTableViewController:UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate
{
    var MAP_TAP_CONTEXT:String?
    var PIN_COORDINATE_CHANGE_CONTEXT:String?
    
    var location:LocationInfo!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    private var marsloc:CLLocation!
    private var mapTap:UILongPressGestureRecognizer!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        marsloc = ChinaGPS.encrypt_WGS_2_GCJ(latitude: location.latitude!.doubleValue, longitude: location.longitude!.doubleValue)
        
        let region = MKCoordinateRegionMakeWithDistance(marsloc.coordinate, 200, 200)
        mapView.setRegion(region, animated: true)
        
        performSelector("placeInitAnnotation:", withObject: marsloc, afterDelay: 0.5)
        
        mapTap = UILongPressGestureRecognizer()
        mapTap.addObserver(self, forKeyPath: "state", options: NSKeyValueObservingOptions.New, context: &MAP_TAP_CONTEXT
        )
        mapView.addGestureRecognizer(mapTap)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if context == &MAP_TAP_CONTEXT
        {
            let state = object?.valueForKey(keyPath!) as! Int
            if state == UIGestureRecognizerState.Began.rawValue
            {
                mapViewTapped(object as! UILongPressGestureRecognizer)
            }
        }
        else
        if context == &PIN_COORDINATE_CHANGE_CONTEXT
        {
            let annotation = object as! PinAnnotation
            showAnnotationCallout(annotation)
        }
    }
    
    func placeInitAnnotation(location:CLLocation)
    {
        dropPinAnnotation(marsloc, tintColor: UIColor.redColor())
    }
    
    func dropPinAnnotation(location:CLLocation, tintColor:UIColor? = nil, removable:Bool = false)
    {
        let annotation = PinAnnotation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        annotation.tintColor = tintColor
        annotation.removable = removable
        mapView.addAnnotation(annotation)
    }
    
    //MARK: map
    func mapViewTapped(gesture:UILongPressGestureRecognizer)
    {
        let touchPoint = gesture.locationInView(mapView)
        let coord = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        clearUserAnnotation()
        dropPinAnnotation(CLLocation(latitude: coord.latitude, longitude: coord.longitude), tintColor: UIColor.blueColor(), removable: true)
    }
    
    func clearUserAnnotation()
    {
        for item in mapView.annotations
        {
            if item is PinAnnotation && (item as! PinAnnotation).removable
            {
                mapView.removeAnnotation(item)
                (item as! PinAnnotation).removeObserver(self, forKeyPath: "coordinate", context: &PIN_COORDINATE_CHANGE_CONTEXT)
            }
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation is PinAnnotation
        {
            let PIN_INDENTIFIER = "PIN_ANNOTATION"
            var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(PIN_INDENTIFIER)
            if anView == nil
            {
                let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: PIN_INDENTIFIER)
                view.pinTintColor = (annotation as! PinAnnotation).tintColor
                view.canShowCallout = true
                view.animatesDrop = true
                anView = view
            }
            
            return anView
        }
        
        return nil
    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView])
    {
        for anView in views
        {
            if anView.annotation is PinAnnotation
            {
                let annotation = anView.annotation as! PinAnnotation
                performSelector("showAnnotationCallout:", withObject: annotation, afterDelay: 0.5)
                
                anView.draggable = annotation.removable
                if annotation.removable
                {
                    annotation.addObserver(self, forKeyPath: "coordinate", options: NSKeyValueObservingOptions.New, context: &PIN_COORDINATE_CHANGE_CONTEXT
                    )
                }
            }
        }
    }
    
    func showAnnotationCallout(annotation:PinAnnotation)
    {
        mapView.selectAnnotation(annotation, animated: true)
        
        let loc = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(loc)
        { (list:[CLPlacemark]?, error:NSError?) in
            if error == nil
            {
                for placemark in list!
                {
                    print(placemark.addressDictionary!)
                }
                
                let placemark = list!.first!
                annotation.subtitle = placemark.name
            }
            else
            {
                let alert = UIAlertController(title: "Geocode: \(error!.code)", message: error?.description, preferredStyle: UIAlertControllerStyle.ActionSheet)
                alert.addAction(UIAlertAction(title: "I've got it!", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    
    //MARK: table
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("LocationDetailCell")!
        return cell
    }
    
    //MARK: gc
    deinit
    {
        clearUserAnnotation()
        mapView.removeAnnotations(mapView.annotations)
        mapTap.removeObserver(self, forKeyPath: "state", context: &MAP_TAP_CONTEXT)
    }
}