//
//  MotionTrackViewController.swift
//  LocationTraker
//
//  Created by larryhou on 2/8/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import MapKit

class MotionTrackViewController:UIViewController, MKMapViewDelegate
{
    @IBOutlet weak var mapView: MKMapView!
    
    var locations:[LocationInfo]!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        var center = CLLocationCoordinate2D()
        var minCoord = CLLocationCoordinate2D(latitude: +180, longitude: +180)
        var maxCoord = CLLocationCoordinate2D(latitude: -180, longitude: -180)
        
        var coordinates:[CLLocationCoordinate2D] = []
        for item in locations
        {
            let mars:CLLocationCoordinate2D = ChinaGPS.encrypt_WGS_2_GCJ(latitude: item.latitude!.doubleValue, longitude: item.longitude!.doubleValue)
            minCoord.latitude = min(minCoord.latitude, mars.latitude)
            maxCoord.latitude = max(maxCoord.latitude, mars.latitude)
            minCoord.longitude = min(minCoord.longitude, mars.longitude)
            maxCoord.longitude = max(minCoord.longitude, mars.longitude)
            center.latitude += mars.latitude
            center.longitude += mars.longitude
            coordinates.append(mars)
        }
        
        center.latitude /= Double(coordinates.count)
        center.longitude /= Double(coordinates.count)
        
        let span = MKCoordinateSpan(latitudeDelta: maxCoord.latitude - minCoord.latitude, longitudeDelta: maxCoord.longitude - minCoord.longitude)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
        
        let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
    }   
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer
    {
        if overlay is MKPolyline
        {
            let view = MKPolylineRenderer(overlay: overlay)
            view.strokeColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.8)
            view.lineWidth = 2.0
            return view
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
}