//
//  PatternTableViewController.swift
//  TexasHoldem
//
//  Created by larryhou on 12/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation
import UIKit

class PatternTableViewController:UITableViewController, UISearchBarDelegate
{
    private let background_queue = dispatch_queue_create("TexasHoldem.background.search", DISPATCH_QUEUE_CONCURRENT)
    
    @IBOutlet weak var search: UISearchBar!
    var model:ViewModel!
    var id:Int = 0
    
    var history:[UniqueRound]!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        history = model.data
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 80
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return history.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if indexPath.row < history.count
        {
            let cell = tableView.dequeueReusableCellWithIdentifier("PatternCell") as! PatternTableViewCell
            
            let data = history[indexPath.row].list[id]
            cell.renderView(data)
            return cell
        }
        else
        {
            let identifier = "LoadingCell"
            
            let cell:UITableViewCell
            if let reuseCell = tableView.dequeueReusableCellWithIdentifier(identifier)
            {
                cell = reuseCell
            }
            else
            {
                cell = UITableViewCell(style: .Default, reuseIdentifier: identifier)
                cell.textLabel?.font = UIFont(name: "Menlo", size: 18)
                cell.textLabel?.text = "..."
            }
            
            return cell
        }
    }
    
    @IBAction func showPatternStats(sender: UIBarButtonItem)
    {
        let alert = PatternStatsPrompt(title: "牌型分布", message: nil, preferredStyle: .ActionSheet)
        alert.setPromptSheet(model.stats[id]!)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    //MARK: search
    func searchBarSearchButtonClicked(searchBar: UISearchBar)
    {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String)
    {
        searchByInput(searchText)
    }
    
    func searchByInput(searchText:String?)
    {
        if let text = searchText
        {
            var integer = NSString(string: text).integerValue
            integer = min(max(0, integer), 255);
            
            if let pattern = HandPattern(rawValue: UInt8(integer))
            {
                dispatch_async(background_queue)
                {
                    self.history = []
                    dispatch_async(dispatch_get_main_queue())
                    {
                        self.tableView.reloadData()
                    }
                    
                    for i in 0..<self.model.data.count
                    {
                        let hand = self.model.data[i].list[self.id]
                        if hand.data.0 == pattern.rawValue
                        {
                            self.history.append(self.model.data[i])
                        }
                        
                        dispatch_async(dispatch_get_main_queue())
                        {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
            else
            {
                history = model.data
            }
        }
        else
        {
            history = model.data
        }
        
        tableView.reloadData()
    }
}
