//
//  PlayerTableViewController.swift
//  TexasHoldem
//
//  Created by larryhou on 12/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation
import UIKit

class PlayerTableViewController:UITableViewController
{
    var model:ViewModel!
    
    //MARK: segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "pattern"
        {
            let dst = segue.destinationViewController as! PatternTableViewController
            dst.model = model
            
            let indexPath = tableView.indexPathForSelectedRow!
            dst.id = indexPath.row
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 75
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return model == nil ? 0 : model.stats.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("PlayerCell")!
        cell.textLabel?.text = String(format: "PLAYER #%02d", indexPath.row + 1)
        return cell
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath)
    {
        let alert = PatternStatsPrompt(title: "牌型分布#\(indexPath.row + 1)", message: nil, preferredStyle: .ActionSheet)
        alert.setPromptSheet(model.stats[indexPath.row]!)
        presentViewController(alert, animated: true, completion: nil)
    }
}
