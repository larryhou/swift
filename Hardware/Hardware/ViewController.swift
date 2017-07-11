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

class HeaderView:UITableViewHeaderFooterView
{
    static let identifier = "SectionHeaderView"
    var title:UILabel?
    override func layoutSubviews()
    {
        if self.title == nil
        {
            let title = UILabel()
            title.font = UIFont(name: "Courier New", size: 36)
            title.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(title)
            self.title = title
            
            let map:[String:Any] = ["title":title]
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(10)-[title]-|", options: .alignAllLeft, metrics: nil, views: map))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[title]-|", options: .alignAllCenterY, metrics: nil, views: map))
            
            backgroundView = UIView()
        }
        tintColor = UIColor.clear
        contentView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
    }
}

class ViewController: UITableViewController
{
    let background = DispatchQueue(label: "data_reload_queue")
    var data:[CategoryType:[ItemInfo]]!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        data = [:]
        self.tableView.allowsSelection = false
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(reload), userInfo: nil, repeats: true)
        
        tableView.register(HeaderView.self, forHeaderFooterViewReuseIdentifier: HeaderView.identifier)
    }
    
    @objc func reload()
    {
        background.async
        {
            HardwareModel.shared.reload()
            DispatchQueue.main.async
            { [unowned self] in
                self.data = [:]
                self.tableView.reloadData()
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 7
    }
    
    private func filter(_ data:[ItemInfo])->[ItemInfo]
    {
        return data.filter({$0.parent == -1})
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let cate = CategoryType(rawValue: section)
        {
            if let count = self.data[cate]?.count, count > 0
            {
                return count
            }
            
            let data = HardwareModel.shared.get(category: cate, reload: false)
            self.data[cate] = data
            return data.count
        }
        
        return 0
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderView.identifier) as! HeaderView
        if let cate = CategoryType(rawValue: section)
        {
            header.title?.text = "\(cate)"
        }
        return header
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
    }
}

