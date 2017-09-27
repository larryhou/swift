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
    enum InfoStyle:Int
    {
        case hex = 0, float, decimal
    }
    
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var background: NSBox!
    
    var style:InfoStyle = .hex
    {
        didSet { renderStyle() }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func mouseDown(with event: NSEvent)
    {
        style = InfoStyle(rawValue: (style.rawValue + 1) % 3)!
    }
    
    func renderStyle()
    {
        if let items = color.components
        {
            switch style
            {
                case .hex:
                    label.stringValue = String(format: "#%02X%02X%02X",
                                               Int(round(items[0] * 255)),
                                               Int(round(items[1] * 255)),
                                               Int(round(items[2] * 255)))
                case .decimal:
                    label.stringValue = String(format: "%03d %03d %03d",
                                               Int(round(items[0] * 255)),
                                               Int(round(items[1] * 255)),
                                               Int(round(items[2] * 255)))
                case .float:
                    label.stringValue = String(format: "%5.3f %5.3f %5.3f",items[0],items[1],items[2])
            }
        }
    }
    
    var color:CGColor = CGColor(red: 1, green: 1, blue: 0, alpha: 1)
    {
        didSet
        {
            let newColor = NSColor(cgColor: color)!
            background.fillColor = newColor
            background.borderColor = newColor
            style = .hex
            
            if let items = color.components
            {
                let components = items.map({$0 * 0.75})
                label.textColor = NSColor(colorSpace: newColor.colorSpace, components: components, count:components.count)
            }
        }
    }
}
