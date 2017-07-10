//
//  ViewController.swift
//  Hardware
//
//  Created by larryhou on 10/7/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import UIKit

class ItemCell:UITableViewCell
{
    @IBOutlet var ib_name:UILabel!
    @IBOutlet var ib_value:UILabel!
}

class ViewController: UITableViewController
{
    var data:[CategoryType:[ItemInfo]]!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        data = HardwareModel.shared.get()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let cate = CategoryType(rawValue: section)
        {
            return data[cate]!.count
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 30))
        let title:UILabel = UILabel(frame: CGRect(x: 10, y: 0, width: 200, height: 30))
        title.font = UIFont(name: "Courier New", size: 30)
        if let cate = CategoryType(rawValue: section)
        {
            title.text = "\(cate)"
        }
        view.addSubview(title)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if let cate = CategoryType(rawValue: section)
        {
            return "\(cate)"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print(indexPath.section, indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell") as! ItemCell
        if let cate = CategoryType(rawValue: indexPath.section), let data = self.data[cate]
        {
            let info = data[indexPath.row]
            cell.ib_value.text = info.value
            cell.ib_name.text = info.name
        }
        
        return cell
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

