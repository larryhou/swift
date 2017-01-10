//
//  MapViewController.swift
//  Maps
//
//  Created by Horacio Garza on 27/08/16.
//  Copyright © 2016 HGarz Studios. All rights reserved.
//

import UIKit
import Foundation
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate{

    @IBOutlet weak var mapView: MKMapView!
    
    var latitude: Double!
    var longitude: Double!
    var annotationTitle: String!
    var locationManager:CLLocationManager!
    
    @IBOutlet weak var lblLocation: UILabel!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        
        let location = CLLocationCoordinate2D(
            latitude: self.latitude, longitude: self.longitude
        )
        
        let span = MKCoordinateSpanMake(0.5, 0.5)
        let region = MKCoordinateRegion(center: location, span: span)
        self.mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = self.annotationTitle
        annotation.subtitle = "Subtitle"
        self.mapView.addAnnotation(annotation)
        // Do any additional setup after loading the view.
        
        
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        
        
        let actualCoordinates =  (x: locations.last?.coordinate.latitude.description, y: locations.last?.coordinate.longitude.description)
        
        self.lblLocation.text = "\(actualCoordinates.x!) \(actualCoordinates.y!)"
        
        let location = locations.last! as CLLocation
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
