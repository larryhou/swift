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
    let removable:Bool
    
    var tintColor:UIColor?
    
    init(latitude:Double, longitude:Double, removable:Bool)
    {
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.title = String(format: "%.7f°,%.7f°",latitude, longitude)
        self.removable = removable
    }
}

class LocationDetailTableViewController:UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate
{
    enum TableSection:Int
    {
        case Motion = 0, Location, Nearby
    }
    
    var MAP_PRESS_CONTEXT:String?
    var PIN_COORDINATE_CHANGE_CONTEXT:String?
    
    var location:LocationInfo!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    private var marsloc:CLLocation!
    private var pressGuesture:UILongPressGestureRecognizer!
    
    private var interests:[MKMapItem]!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        marsloc = ChinaGPS.encrypt_WGS_2_GCJ(latitude: location.latitude!.doubleValue, longitude: location.longitude!.doubleValue)
        
        let region = MKCoordinateRegionMakeWithDistance(marsloc.coordinate, 200, 200)
        mapView.setRegion(region, animated: true)
        
        performSelector("placeInitAnnotation:", withObject: marsloc, afterDelay: 0.5)
        
        pressGuesture = UILongPressGestureRecognizer()
        pressGuesture.addObserver(self, forKeyPath: "state", options: NSKeyValueObservingOptions.New, context: &MAP_PRESS_CONTEXT
        )
        mapView.addGestureRecognizer(pressGuesture)
        searchInMapView("饭|菜|吃|川")
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if context == &MAP_PRESS_CONTEXT
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
        let annotation = PinAnnotation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, removable:removable)
        annotation.tintColor = tintColor
        mapView.addAnnotation(annotation)
        
        if annotation.removable
        {
            annotation.addObserver(self, forKeyPath: "coordinate", options: NSKeyValueObservingOptions.New, context: &PIN_COORDINATE_CHANGE_CONTEXT
            )
            
            mapView.setRegion(MKCoordinateRegionMakeWithDistance(annotation.coordinate, 50, 50), animated: true)
        }
        
        performSelector("showAnnotationCallout:", withObject: annotation, afterDelay: 0.5)
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
                (item as! PinAnnotation).removeObserver(self, forKeyPath: "coordinate")
                mapView.removeAnnotation(item)
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
                view.draggable = (annotation as! PinAnnotation).removable
                view.canShowCallout = true
                view.animatesDrop = true
                anView = view
            }
            
            anView?.annotation = annotation
            return anView
        }
        
        return nil
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
                let alert = UIAlertController(title: nil, message: error?.description, preferredStyle: UIAlertControllerStyle.ActionSheet)
                alert.addAction(UIAlertAction(title: "I've got it!", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    func searchInMapView(keyword:String)
    {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = keyword
        request.region = mapView.region
        
        MKLocalSearch(request: request).startWithCompletionHandler
        { (response:MKLocalSearchResponse?, error:NSError?) -> Void in
            
            for item in response!.mapItems
            {
                print(item.name!)
                
            }
            
            self.interests = response!.mapItems
            self.tableView.reloadData()
        }
    }
    
    //MARK: table
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return interests == nil ? 2 : 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch section
        {
            case TableSection.Motion.rawValue:
                return 3
            
            case TableSection.Location.rawValue:
                return 3
            
            default:
                return interests.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let gpsfmt = "%.10f°, %.10f°"
        
        switch indexPath.section
        {
            case TableSection.Motion.rawValue:
                let CELL_IDENTIFIER = "MotionCell"
                var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER)
                if cell == nil
                {
                    cell = UITableViewCell(style: UITableViewCellStyle.Value2, reuseIdentifier: CELL_IDENTIFIER)
                }
                cell?.selectionStyle = UITableViewCellSelectionStyle.None
                switch indexPath.row
                {
                    case 0:
                        cell?.textLabel?.text = "速度"
                        cell?.detailTextLabel?.text = getSpeedText(location.speed!.doubleValue)
                    case 1:
                        cell?.textLabel?.text = "方向"
                        cell?.detailTextLabel?.text = getDirectionText(location.course!.doubleValue)
                    default:
                        cell?.textLabel?.text = "海拔"
                        cell?.detailTextLabel?.text = getAltitudeText(location.altitude!.doubleValue)
                }
                return cell!
            
            case TableSection.Location.rawValue:
                let CELL_IDENTIFIER = "LocationCell"
                var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER)
                if cell == nil
                {
                    cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: CELL_IDENTIFIER)
                }
                cell?.selectionStyle = UITableViewCellSelectionStyle.Default
                switch indexPath.row
                {
                    case 0:
                        cell?.textLabel?.text = String(format: "标准 " + gpsfmt, location.latitude!.doubleValue, location.longitude!.doubleValue)
                    case 1:
                        cell?.textLabel?.text = String(format: "火星 " + gpsfmt, marsloc.coordinate.latitude, marsloc.coordinate.longitude)
                    default:
                        let biduloc = ChinaGPS.baidu_encrypt(latitude: marsloc.coordinate.latitude, longitude: marsloc.coordinate.longitude)
                        cell?.textLabel?.text = String(format: "百度 " + gpsfmt, biduloc.coordinate.latitude, biduloc.coordinate.longitude)
                }
                return cell!
            default:
                let CELL_IDENTIFIER = "InterestCell"
                var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER)
                if cell == nil
                {
                    cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: CELL_IDENTIFIER)
                }
                cell?.selectionStyle = UITableViewCellSelectionStyle.Default
                
                let mapItem = interests[indexPath.row]
                cell?.textLabel?.text = mapItem.name!
                return cell!
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        switch section
        {
            case TableSection.Motion.rawValue:return "运动信息"
            case TableSection.Location.rawValue:return "定位信息"
            case TableSection.Nearby.rawValue:return "周边餐厅"
            default:return nil
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let cell = tableView.cellForRowAtIndexPath(tableView.indexPathForSelectedRow!)!
        
        func gps2str(latitude:Double, longitude:Double) -> String
        {
            return String(format: "%.10f,%.10f", latitude, longitude)
        }
        
        switch indexPath.section
        {
            case TableSection.Location.rawValue:
                switch indexPath.row
                {
                    case 0:
                        UIPasteboard.generalPasteboard().string = gps2str(location.latitude!.doubleValue, longitude: location.longitude!.doubleValue)
                    case 1:
                        UIPasteboard.generalPasteboard().string = gps2str(marsloc.coordinate.latitude, longitude: marsloc.coordinate.longitude)
                    case 2:
                        let bidudoc = ChinaGPS.baidu_encrypt(latitude: marsloc.coordinate.latitude, longitude: marsloc.coordinate.longitude)
                        UIPasteboard.generalPasteboard().string = gps2str(bidudoc.coordinate.latitude, longitude: bidudoc.coordinate.longitude)
                    default:
                        UIPasteboard.generalPasteboard().string = cell.textLabel!.text
                }

            case TableSection.Nearby.rawValue:
                let location = interests[indexPath.row].placemark.location!
                clearUserAnnotation()
                dropPinAnnotation(location, tintColor: UIColor.purpleColor(), removable: true)
            default:break
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func getAltitudeText(value:Double) -> String
    {
        switch value
        {
            case let x where x >= 0:return String(format: "%.1fm", value)
            default:return "未知"
        }
    }
    
    func getSpeedText(value:Double) -> String
    {
        if value >= 0
        {
            return String(format: "%.2fm/s %.0fkm/s", value, value * 3600 / 1000)
        }
        
        return "未知"
    }
    
    func getDirectionText(angle:Double) -> String
    {
        var result:String
        switch angle
        {
            case 000..<090: result = String(format:"北偏东 %.1f°", angle)
            case 090..<180: result = String(format:"东偏南 %.1f°", angle - 090)
            case 180..<270: result = String(format:"南偏西 %.1f°", angle - 180)
            case 270..<360: result = String(format:"西偏北 %.1f°", angle - 270)
            default:result = "未知"
        }

        return result
    }
    
    //MARK: gc
    deinit
    {
        clearUserAnnotation()
        mapView.removeAnnotations(mapView.annotations)
        pressGuesture.removeObserver(self, forKeyPath: "state", context: &MAP_PRESS_CONTEXT)
    }
}