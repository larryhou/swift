//
//  CitiesViewController.swift
//  Maps
//
//  Created by Horacio Garza on 27/08/16.
//  Copyright © 2016 HGarz Studios. All rights reserved.
//

import Foundation
import UIKit
import KVNProgress
import Alamofire
import SwiftyJSON


class CitiesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    let paises = ["Mexico", "Australia", "Germany", "Peru", "Venezuela", "Spain", "Argentina", "China", "Japan", "North Korea"]
    
    var cellTitle: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        KVNProgress.showErrorWithStatus("Listo prro")
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segue_to_map" {
            
            let vc = segue.destinationViewController as? MapViewController
            vc?.latitude = Double(arc4random_uniform(100) + 10)
            vc?.longitude = Double(arc4random_uniform(100) + 10)
            vc?.annotationTitle = self.cellTitle
            
        }
    }
    
    //MARK: Table View
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return section == 0 ? "Ciudades Nacionales" : "Ciudades Internacionales"
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return section == 0 ? 10 : 5
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            
            let cell: UITableViewCell = UITableViewCell()

            cell.textLabel?.text = "\(indexPath.section.description)  -  \(indexPath.row.description)"  //paises[indexPath.row]
            return cell
        }else{
            let cell = tableView.dequeueReusableCellWithIdentifier("Custom")
            (cell?.viewWithTag(100) as? UILabel)?.text = "\(indexPath.section.description)  -  \(indexPath.row.description)"  //paises[indexPath.row]
            
            return cell!
        }
        
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            return 48
        }else{
            return 300
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        self.cellTitle = (cell?.viewWithTag(100) as? UILabel)?.text
        
        self.performSegueWithIdentifier("segue_to_map", sender: nil)
        
    }
}


