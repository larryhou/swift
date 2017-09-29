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
        return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: items)!
    }
}

extension NSView
{
    @objc func color(at position:CGPoint)->CGColor
    {
        guard bounds.contains(position) else {return .black}
        
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
        
        return .black
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
        if bounds.contains(point)
        {
            position = point
            delegate?.colorPicker(self, eventWith: color(at: point))
        }
    }
    
    override func mouseDragged(with event: NSEvent)
    {
        let point = convert(event.locationInWindow, from: nil)
        if bounds.contains(point)
        {
            position = point
            delegate?.colorPicker(self, eventWith: color(at: point))
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
    var drawArea:NSRect = NSRect()
    var theme:ColorTheme = .rgb
    {
        didSet { setNeedsDisplay(bounds) }
    }
    
    required init?(coder decoder: NSCoder)
    {
        super.init(coder: decoder)
        
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.layer?.masksToBounds = true
        
        drawArea = bounds.insetBy(dx: 5, dy: 5)
    }
    
    override func color(at position: CGPoint) -> CGColor
    {
        return super.color(at: CGPoint(x: bounds.width / 2, y: position.y))
    }
    
    override func restoreOrigin()
    {
        position = CGPoint(x: drawArea.minX + drawArea.width / 2, y: drawArea.minY - 1)
    }
    
    override func draw(_ dirtyRect: NSRect)
    {
        guard let context = NSGraphicsContext.current else { return }
        drawArea = bounds.insetBy(dx: 5, dy: 5)
        
        context.saveGraphicsState()
        context.imageInterpolation = .high
        context.shouldAntialias = true
        
        let canvas = context.cgContext
        let colors:[CGColor]
        if theme == .rgb
        {
            colors = [NSColor.red.cgColor, NSColor.yellow.cgColor, NSColor.green.cgColor, NSColor.cyan.cgColor , NSColor.blue.cgColor, NSColor.magenta.cgColor, NSColor.red.cgColor]
        }
        else
        {
            colors = [NSColor.red.cgColor, NSColor.orange.cgColor,NSColor.yellow.cgColor,NSColor.green.cgColor,NSColor.blue.cgColor, NSColor.purple.cgColor, NSColor.red.cgColor]
        }
        let locations:[CGFloat] = [0, 1.0/6, 2.0/6, 3.0/6, 4.0/6, 5.0/6, 1]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations)!
        
        canvas.addRect(drawArea)
        canvas.drawLinearGradient(gradient, start: CGPoint(x: drawArea.minX, y: drawArea.maxY), end: CGPoint(x:drawArea.minX, y:drawArea.minY), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        context.restoreGraphicsState()
    }
    
    func getComplementoryColors()->[CGColor]
    {
        var list:[CGColor] = [color(at: position)]
        list.append(list[0].opposite)
        return list
    }
    
    func getTriadicColors()->[CGColor]
    {
        return getAdjacentColors(angle: 120)
    }
    
    func getTetradicColors()->[CGColor]
    {
        var list:[CGColor] = [color(at: position)]
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
            list.append(color(at: point))
        }
        
        return list
    }
    
    func getAnalogousColors()->[CGColor]
    {
        return getAdjacentColors(angle: 30)
    }
    
    func getAdjacentColors(angle:Int = 30)->[CGColor]
    {
        return getAdjacentColors(density: Int(360 / CGFloat(angle)))
    }
    
    func getAdjacentColors(density:Int = 24)->[CGColor]
    {
        var list:[CGColor] = [color(at: position)]
        var stop = position.y
        for _ in 1..<density
        {
            stop += bounds.height / CGFloat(density)
            if stop > bounds.height
            {
                stop -= bounds.height
            }
            
            let point = CGPoint(x: position.x, y: stop)
            list.append(color(at: point))
        }
        
        return list
    }
}


class ColorPlatterView: ColorPickerView
{
    var domainColor:CGColor = NSColor.yellow.cgColor
    
    var dark:CGFloat { return min(1, (position.y - drawArea.minY) / drawArea.height) }
    var tint:CGFloat { return min(1, (position.x - drawArea.minX) / drawArea.width) }
    
    var drawArea:NSRect = NSRect()
    
    required init?(coder decoder: NSCoder)
    {
        super.init(coder: decoder)
        
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.layer?.masksToBounds = true
        
        drawArea = bounds.insetBy(dx: 10, dy: 10)
    }
    
    override func restoreOrigin()
    {
        position = CGPoint(x: drawArea.maxX, y: drawArea.maxY)
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
        drawArea = bounds.insetBy(dx: 10, dy: 10)
        
        context.saveGraphicsState()
        context.imageInterpolation = .high
        context.shouldAntialias = true
        
        let canvas = context.cgContext
        var colors:[CGColor]!, gradient:CGGradient!
        
        canvas.setFillColor(.white)
        canvas.fill(bounds)
        
        canvas.addRect(drawArea)
        colors = [domainColor.copy(alpha: 0)!, domainColor]
        gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])
        canvas.drawLinearGradient(gradient!, start: CGPoint(x:drawArea.minX, y:drawArea.minY), end: CGPoint(x:drawArea.maxX, y:drawArea.minY), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        canvas.addRect(drawArea)
        colors = [NSColor.black.cgColor.copy(alpha: 0)!, NSColor.black.cgColor]
        gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])
        canvas.drawLinearGradient(gradient!, start: CGPoint(x:drawArea.minX, y:drawArea.maxY), end: CGPoint(x:drawArea.minX, y:drawArea.minY), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        context.restoreGraphicsState()
    }
}
