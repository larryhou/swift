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
    
    init(latitude:Double, longitude:Double)
    {
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.title = String(format: "%.7f°,%.7f°",latitude, longitude)
    }
}

class LocationDetailTableViewController:UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate
{
    var location:LocationInfo!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    private var marsloc:CLLocation!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        marsloc = ChinaGPS.encrypt_WGS_2_GCJ(latitude: location.latitude!.doubleValue, longitude: location.longitude!.doubleValue)
        
        let region = MKCoordinateRegionMakeWithDistance(marsloc.coordinate, 500, 500)
        mapView.setRegion(region, animated: true)
        
        performSelector("pinAnnotation", withObject: nil, afterDelay: 0.5)
    }
    
    func pinAnnotation()
    {
        let annotation = PinAnnotation(latitude: marsloc.coordinate.latitude, longitude: marsloc.coordinate.longitude)
        mapView.addAnnotation(annotation)
    }
    
    //MARK: map
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation is PinAnnotation
        {
            let PIN_INDENTIFIER = "PIN_ANNOTATION"
            var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(PIN_INDENTIFIER)
            if anView == nil
            {
                let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: PIN_INDENTIFIER)
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
                performSelector("autoCallout:", withObject: annotation, afterDelay: 0.5)
            }
        }
    }
    
    func autoCallout(annotation:PinAnnotation)
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
                annotation.subtitle = (placemark.addressDictionary?["Name"] as! String)
            }
            else
            {
                let alert = UIAlertController(title: "Geocode: \(error!.code)", message: error?.description, preferredStyle: UIAlertControllerStyle.ActionSheet)
                alert.addAction(UIAlertAction(title: "", style: UIAlertActionStyle.Destructive, handler: nil))
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
        mapView.removeAnnotations(mapView.annotations)
    }
}