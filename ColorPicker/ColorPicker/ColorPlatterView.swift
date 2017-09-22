//
//  ColorPlatterView.swift
//  ColorPicker
//
//  Created by larryhou on 21/09/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Cocoa

extension CGColor
{
    var opposite:CGColor
    {
        var items = components!
        for i in 0..<numberOfComponents-1
        {
            items[i] = 1 - items[i]
        }
        return CGColor(colorSpace: colorSpace!, components: items)!
    }
}

extension NSView
{
    func color(at position:CGPoint)->CGColor?
    {
        guard bounds.contains(position) else {return nil}
        
        var pixel:[CUnsignedChar] = Array(repeating: 0, count: 4)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        if let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue)
        {
            context.translateBy(x: -position.x, y: -position.y)
            if let layer = self.layer
            {
                layer.render(in: context)
                return CGColor(red: CGFloat(pixel[0])/255.0,
                             green: CGFloat(pixel[1])/255.0,
                              blue: CGFloat(pixel[2])/255.0,
                             alpha: 1)
            }
        }
        
        return nil
    }
}

class ColorPickerView : NSView
{
    @IBOutlet
    var delegate:ColorPickerDelegate?
    var position = CGPoint()
    
    override func mouseDown(with event: NSEvent)
    {
        let point = convert(event.locationInWindow, from: nil)
        if let color = color(at: point)
        {
            position = point
            delegate?.colorPicker(self, eventWith: color)
        }
    }
    
    override func mouseDragged(with event: NSEvent)
    {
        let point = convert(event.locationInWindow, from: nil)
        if let color = color(at: point)
        {
            position = point
            delegate?.colorPicker(self, eventWith: color)
        }
    }
}

@objc
protocol ColorPickerDelegate
{
    func colorPicker(_ sender:NSView, eventWith color:CGColor)
}

class ColorBarView: ColorPickerView
{
    required init?(coder decoder: NSCoder)
    {
        super.init(coder: decoder)
        
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.layer?.masksToBounds = true
    }
    
    override func draw(_ dirtyRect: NSRect)
    {
        guard let context = NSGraphicsContext.current else { return }
        
        context.saveGraphicsState()
        context.imageInterpolation = .high
        context.shouldAntialias = true
        
        let canvas = context.cgContext
        let colors = [NSColor.red.cgColor, NSColor.yellow.cgColor, NSColor.green.cgColor, NSColor.cyan.cgColor , NSColor.blue.cgColor, CGColor(red: 1, green: 0, blue: 1, alpha: 1), NSColor.red.cgColor]
        let locations:[CGFloat] = [0, 1.0/6, 2.0/6, 3.0/6, 4.0/6, 5.0/6, 1]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations)!
        
        canvas.addRect(bounds)
        canvas.drawLinearGradient(gradient, start: CGPoint(x: 0, y: bounds.maxY), end: CGPoint(), options: CGGradientDrawingOptions(rawValue: 0))
        
        context.restoreGraphicsState()
    }
    
    func seekComplementoryColors()->[CGColor]
    {
        var list:[CGColor] = [color(at: position)!]
        
        var stop = position.y
        for _ in 1..<2
        {
            stop += bounds.height / 2
            if stop > bounds.height
            {
                stop -= bounds.height
            }
            
            let point = CGPoint(x: position.x, y: stop)
            list.append(color(at: point)!)
        }
        
        return list
    }
    
    func seekTriadicColors()->[CGColor]
    {
        var list:[CGColor] = [color(at: position)!]
        var stop = position.y
        for _ in 1..<3
        {
            stop += bounds.height / 3
            if stop > bounds.height
            {
                stop -= bounds.height
            }
            
            let point = CGPoint(x: position.x, y: stop)
            list.append(color(at: point)!)
        }
        
        return list
    }
    
    func seekTetradicColors()->[CGColor]
    {
        var list:[CGColor] = [color(at: position)!]
        var stop = position.y
        for i in 1..<4
        {
            if i % 2 == 0
            {
                stop += bounds.height / 3
            }
            else
            {
                stop += bounds.height / 6
            }
            
            if stop > bounds.height
            {
                stop -= bounds.height
            }
            
            let point = CGPoint(x: position.x, y: stop)
            list.append(color(at: point)!)
        }
        
        return list
    }
    
    func seekAnalogousColors()->[CGColor]
    {
        var list:[CGColor] = [color(at: position)!]
        var stop = position.y
        for _ in 1..<12
        {
            stop += bounds.height / 12
            if stop > bounds.height
            {
                stop -= bounds.height
            }
            
            let point = CGPoint(x: position.x, y: stop)
            list.append(color(at: point)!)
        }
        
        return list
    }
    
    func seekNeutralColors()->[CGColor]
    {
        var list:[CGColor] = [color(at: position)!]
        var stop = position.y
        for _ in 1..<24
        {
            stop += bounds.height / 24
            if stop > bounds.height
            {
                stop -= bounds.height
            }
            
            let point = CGPoint(x: position.x, y: stop)
            list.append(color(at: point)!)
        }
        
        return list
    }
}


class ColorPlatterView: ColorPickerView
{
    var domainColor:CGColor = NSColor.yellow.cgColor
    
    var dark:CGFloat { return position.y / bounds.height }
    var tint:CGFloat { return position.x / bounds.width }
    
    required init?(coder decoder: NSCoder)
    {
        super.init(coder: decoder)
        
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.layer?.masksToBounds = true
    }
    
    func setColor(_ color:CGColor)
    {
        domainColor = color
        setNeedsDisplay(bounds)
    }
    
    func blendColor(_ color:CGColor? = nil)->CGColor
    {
        var list = (color ?? domainColor).components!
        for n in 0..<list.count-1
        {
            list[n] = dark * ((1-tint) * 1 + tint * list[n])
        }
        return CGColor(colorSpace: domainColor.colorSpace!, components: list)!
    }
    
    override func mouseDown(with event: NSEvent)
    {
        let point = convert(event.locationInWindow, from: nil)
        if bounds.contains(point)
        {
            position = point
            delegate?.colorPicker(self, eventWith: blendColor())
        }
    }
    
    override func mouseDragged(with event: NSEvent)
    {
        let point = convert(event.locationInWindow, from: nil)
        if bounds.contains(point)
        {
            position = point
            delegate?.colorPicker(self, eventWith: blendColor())
        }
    }
    
    override func draw(_ dirtyRect: NSRect)
    {
        guard let context = NSGraphicsContext.current else {return}
        context.saveGraphicsState()
        context.imageInterpolation = .high
        context.shouldAntialias = true
        
        let canvas = context.cgContext
        var colors:[CGColor]!, locations:[CGFloat]!, gradient:CGGradient!
        
        canvas.setFillColor(.white)
        canvas.fill(bounds)
        
        canvas.addRect(bounds)
        colors = [domainColor.copy(alpha: 0)!, domainColor]
        locations = [0, 1]
        gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations)
        canvas.drawLinearGradient(gradient!, start: CGPoint(), end: CGPoint(x:bounds.maxX, y:0), options: CGGradientDrawingOptions(rawValue: 0))
        
        canvas.addRect(bounds)
        colors = [NSColor.black.cgColor.copy(alpha: 0)!, NSColor.black.cgColor]
        locations = [0, 1]
        gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations)
        canvas.drawLinearGradient(gradient!, start: CGPoint(x:0, y:bounds.maxY), end: CGPoint(), options: CGGradientDrawingOptions(rawValue: 0))
        
        context.restoreGraphicsState()
        // Drawing code here.
    }
}

class ColorInfoView: NSBox
{
    @IBOutlet weak var r:NSTextField!
    @IBOutlet weak var g:NSTextField!
    @IBOutlet weak var b:NSTextField!
    @IBOutlet weak var rectangle:NSView!
    
    required init?(coder decoder: NSCoder)
    {
        super.init(coder: decoder)
        
        cornerRadius = 5

    }
    
    var color:CGColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    {
        didSet
        {
            let nsColor = NSColor(cgColor: color)!
            borderColor = nsColor
            if let items = color.components
            {
                let list = [r!, g!, b!]
                let name = ["R", "G", "B"]
                for i in 0..<list.count
                {
                    let value = Int(round(items[i] * 255))
                    list[i].stringValue = String(format: "%@ %02X %3d %5.3f", name[i] ,value, value, items[i])
                    list[i].textColor = nsColor
                }
                fillColor = NSColor(red: 1 - items[0], green: 1 - items[1], blue: 1 - items[2], alpha: 1)
            }
            rectangle.layer?.backgroundColor = color
        }
    }
}
