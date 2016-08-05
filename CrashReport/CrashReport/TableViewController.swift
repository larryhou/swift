//
//  ViewController.swift
//  CrashReport
//
//  Created by larryhou on 8/4/16.
//  Copyright © 2016 larryhou. All rights reserved.
//

import UIKit

enum TestMethod:Int
{
    case null = 0, memory, cpu, abort, none
    
    var description:String
    {
        switch self
        {
            case .null:return "null"
            case .memory:return "memory"
            case .cpu:return "cpu"
            case .abort:return "abort"
            case .none:return "none"
        }
    }
}

class TableViewController: UITableViewController
{

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell")!
        
        if let method = TestMethod(rawValue: indexPath.row)
        {
            switch method
            {
                case .null:
                    cell.textLabel?.text = "空指针访问"
                    break
                
                case .memory:
                    cell.textLabel?.text = "内存使用超限制"
                    break
                
                case .cpu:
                    cell.textLabel?.text = "CPU使用超限制"
                    break
                
                case .abort:
                    cell.textLabel?.text = "使用abort()制造闪退"
                    break
                
                case .none:
                    cell.textLabel?.text = "等待手动退出"
                    break
            }
        }
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "action"
        {
            if let controller = segue.destination as? ViewController
            {
                if let index = tableView.indexPathForSelectedRow, let method = TestMethod(rawValue: index.row)
                {
                    tableView.deselectRow(at: index, animated: true)
                    controller.method = method
                    
                    if let text = tableView.cellForRow(at: index)?.textLabel?.text
                    {
                        controller.bartitle = text
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

