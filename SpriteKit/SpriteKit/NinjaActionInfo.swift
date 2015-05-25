//
//  NinjaActionInfo.swift
//  SpriteKit
//
//  Created by larryhou on 24/5/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import Foundation

class LayerFrameInfo
{
    let index:Int
    let texture:String
    let length:Int
    
    let x, y:Int
    let scaleX, scaleY:Double
    
    let rotation:Double
    let alpha:Double
    
    init(index:Int, texture:String, length:Int, x:Int, y:Int, scaleX:Double, scaleY:Double, rotation:Double, alpha:Double)
    {
        self.index = index
        self.texture = texture
        self.length = length
        self.x = x
        self.y = y
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.rotation = rotation
        self.alpha = alpha
    }
    
    var position:Int { return index + length }
}

class ActionLayerInfo
{
    let id:Int
    let name:String
    var frames:[LayerFrameInfo]
    
    init(id:Int, name:String)
    {
        self.id = id
        self.name = name
        self.frames = []
    }
    
    var length:Int
    {
        var count = 0
        for i in 0..<frames.count
        {
            count += frames[i].length
        }
        
        return count
    }
    
    func decode(data:NSDictionary)
    {
        if data["frame"] == nil
        {
            return
        }
        
        let list = data["frame"] as! NSArray
        
        var position:Int = 0
        for i in 0..<list.count
        {
            let item = list[i] as! NSDictionary
            let index = (item["index"] as! NSString).integerValue
            let length = (item["length"] as! NSString).integerValue
            
            var texture:String = ""
            
            var x = 0, y = 0
            var scaleX = 1.0, scaleY = 1.0
            var rotation = 0.0
            var alpha = 1.0
            
            if item["element"] != nil
            {
                let element = (item["element"] as! NSArray)[0] as! NSDictionary
                texture = element["filename"] as! String
                texture = texture.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
                x = (element["x"] as! NSString).integerValue
                y = (element["y"] as! NSString).integerValue
                scaleX = (element["scaleX"] as! NSString).doubleValue
                scaleY = (element["scaleY"] as! NSString).doubleValue
                rotation = (element["rotation"] as! NSString).doubleValue
                alpha = (element["alpha"] as! NSString).doubleValue
            }
            
            let frame = LayerFrameInfo(index: index,
                texture: texture,
                length: length,
                x: x, y: y,
                scaleX: scaleX, scaleY: scaleY,
                rotation: rotation,
                alpha:alpha)
            frames.append(frame)
        }
    }
}

class NinjaActionInfo
{
    let index:Int
    let name:String
    var layers:[ActionLayerInfo]
    
    init(index:Int, name:String)
    {
        self.index = index
        self.name = name
        self.layers = []
    }
    
    var length:Int
    {
        var count = 0
        for i in 0..<layers.count
        {
            count = max(count, layers[i].length)
        }
        
        return count
    }
    
    func decode(data:NSDictionary)
    {
        let list = data.valueForKeyPath("layer") as! NSArray
        for i in 0..<list.count
        {
            let item = list[i] as! NSDictionary
            var layer = ActionLayerInfo(id: (item["id"] as! NSString).integerValue, name: item["name"] as! String)
            layer.decode(item)
            
            layers.append(layer)
        }
    }
}