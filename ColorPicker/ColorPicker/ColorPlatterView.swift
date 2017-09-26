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
            context.translateBy(x: -round(position.x), y: round(-position.y))
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
    
    func restoreOrigin()
    {
        position = CGPoint()
    }
    
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
    
    override func restoreOrigin()
    {
        position = CGPoint(x: bounds.width / 2, y: 0)
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
    
    func seekNeutralColors(density:Int = 24)->[CGColor]
    {
        var list:[CGColor] = [color(at: position)!]
        var stop = position.y
        for _ in 1..<density
        {
            stop += bounds.height / CGFloat(density)
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
    
    var dark:CGFloat { return min(1, (position.y - interestArea.minY) / interestArea.height) }
    var tint:CGFloat { return min(1, (position.x - interestArea.minX) / interestArea.width) }
    
    var interestArea:NSRect = NSRect()
    
    required init?(coder decoder: NSCoder)
    {
        super.init(coder: decoder)
        
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.layer?.masksToBounds = true
        
        interestArea = bounds.insetBy(dx: 10, dy: 10)
    }
    
    override func restoreOrigin()
    {
        position = CGPoint(x: interestArea.maxX, y: interestArea.maxY)
    }
    
    func setColor(_ color:CGColor)
    {
        domainColor = color
        restoreOrigin()
        
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
        print(point.x, point.y)
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
        interestArea = bounds.insetBy(dx: 10, dy: 10)
        
        context.saveGraphicsState()
        context.imageInterpolation = .high
        context.shouldAntialias = true
        
        let canvas = context.cgContext
        var colors:[CGColor]!, gradient:CGGradient!
        
        canvas.setFillColor(.white)
        canvas.fill(bounds)
        
        canvas.addRect(interestArea)
        colors = [domainColor.copy(alpha: 0)!, domainColor]
        gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])
        canvas.drawLinearGradient(gradient!, start: CGPoint(x:interestArea.minX, y:interestArea.minY), end: CGPoint(x:interestArea.maxX, y:interestArea.minY), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        canvas.addRect(interestArea)
        colors = [NSColor.black.cgColor.copy(alpha: 0)!, NSColor.black.cgColor]
        gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])
        canvas.drawLinearGradient(gradient!, start: CGPoint(x:interestArea.minX, y:interestArea.maxY), end: CGPoint(x:interestArea.minX, y:interestArea.minY), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        context.restoreGraphicsState()
    }
}
