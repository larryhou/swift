//
//  ViewController.swift
//  Tachograph
//
//  Created by larryhou on 30/6/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController, TCPConnectionDelegate
{
    func tcp(connection: TCPConnection, data: Data)
    {
        print("data", String(data:data, encoding:.utf8)!)
        do
        {
            if let obj = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary
            {
                print(obj)
            }
        }
        catch
        {
            print(error)
        }
    }
    
    var flag = false
    func tcp(connection: TCPConnection, sendEvent: Stream.Event)
    {
        print("send", sendEvent)
        if sendEvent == .openCompleted
        {
            let data:[String:Int] = ["token":1, "msg_id":769]
            connection.send(data: data)
        }
    }
    
    func tcp(connection: TCPConnection, readEvent: Stream.Event)
    {
        print("read", readEvent)
    }
    
    var session:TCPConnection!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        session = TCPConnection()
        session.delegate = self
        session.connect(address: "192.168.0.103", port: 8800)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

