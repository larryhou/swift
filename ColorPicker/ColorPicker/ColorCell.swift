//
//  ColorCell.swift
//  ColorPicker
//
//  Created by larryhou on 22/09/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Cocoa

class ColorCell: NSCollectionViewItem
{
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var background: NSBox!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    var color:CGColor = CGColor(red: 1, green: 1, blue: 0, alpha: 1)
    {
        didSet
        {
            background.fillColor = NSColor(cgColor: color)!
            background.borderColor = NSColor(cgColor: color)!
            
            if let items = color.components
            {
                label.stringValue = String(format: "#%02X%02X%02X",
                                           Int(round(items[0] * 255)),
                                           Int(round(items[1] * 255)),
                                           Int(round(items[2] * 255)))
            }
        }
    }
}
