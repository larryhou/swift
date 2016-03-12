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
    @IBOutlet weak var search: UISearchBar!
    var model:ViewModel!
    var id:Int = 0
    
    var history:[UniqueRound]!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        history = model.data
        search.inputAccessoryView = UIView(frame: CGRect.zero)
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
        let cell = tableView.dequeueReusableCellWithIdentifier("PatternCell") as! PatternTableViewCell
        
        let data = history[indexPath.row].list[id]
        cell.renderView(data)
        
        return cell
    }
    
    //MARK: search
    func searchBarSearchButtonClicked(searchBar: UISearchBar)
    {
        filterByInputText(searchBar.text)
        searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String)
    {
        print(searchText)
        filterByInputText(searchText)
    }
    
    func filterByInputText(searchText:String?)
    {
        if let text = searchText
        {
            var integer = NSString(string: text).integerValue
            integer = min(max(0, integer), 255);
            
            if let pattern = HandPattern(rawValue: UInt8(integer))
            {
                var result:[UniqueRound] = []
                for i in 0..<model.data.count
                {
                    let hand = model.data[i].list[id]
                    if hand.data.0 == pattern.rawValue
                    {
                        result.append(model.data[i])
                    }
                }
                
                history = result
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
