//
//  ViewController.swift
//  ByteArray
//
//  Created by larryhou on 5/20/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        var bytes = ByteArray()
        bytes.endian = ByteArray.Endian.BIG_ENIDAN
        
        bytes.writeBoolean(true)
        bytes.writeUTF("侯坤峰")
        bytes.writeDouble(M_PI)
        
        println(bytes.position)
        
        bytes.position = 0
        println(bytes.readBoolean())
        println(bytes.readUTF())
        println(bytes.readDouble())
        
        var data = ByteArray()
        data.endian = bytes.endian
        
//        bytes.position = 1
//        bytes.readBytes(data, offset: 0, length: 11)
        
        data.writeBytes(bytes, offset: 1, length: 11)
        
        println(data.length)
        data.position = 0
        println(data.readUTF())
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

