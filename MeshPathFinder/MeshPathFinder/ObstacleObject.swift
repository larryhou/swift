//
//  ObstacleObject.swift
//  MeshPathFinder
//
//  Created by larryhou on 7/26/16.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation
import CoreGraphics
import GameplayKit

extension CGMutablePath
{
    func circle(radius:CGFloat)->CGPath
    {
        return circle(width: radius, height: radius)
    }
    
    func circle(width:CGFloat, height:CGFloat)->CGPath
    {
        addEllipseIn(nil, rect: CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height)))
        return self
    }
    
    func square(size:CGFloat)->CGPath
    {
        return rectangle(width: size, height: size)
    }
    
    func rectangle(width:CGFloat, height:CGFloat)->CGPath
    {
        addRect(nil, rect: CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height)))
        return self
    }
    
    func triangle(dimension:CGFloat, equilateral:Bool)->CGPath
    {
        return polygon(sideCount: 3, dimension: dimension, equilateral: equilateral)
    }
    
    func polygon(sideCount count:Int, dimension:CGFloat, equilateral:Bool)->CGPath
    {
        var parts:[CGFloat] = []
        for _ in 1...count
        {
            let num = GKRandomSource.sharedRandom().nextInt(withUpperBound: 360)
            parts.append(CGFloat(num))
        }
        
        let divider = parts.reduce(0) { $0 + $1 }
        
        let radius = dimension * 0.5, total = CGFloat.pi * 2.0
        var vertex:[(x:CGFloat, y:CGFloat)] = [], angle:CGFloat = 0.0, offset = CGPoint()
        for i in 0..<count
        {
            let delta:CGFloat
            if !equilateral
            {
                delta = total * parts[i] / divider
            }
            else
            {
                delta = total / CGFloat(count)
            }
            
            angle += delta
            print(String(format: "%03d %5.1f°", i + 1, delta * 180 / CGFloat.pi))
            
            let point = (x:radius * sin(angle), y:radius * cos(angle))
            vertex.append(point)
            
            offset.x = min(point.x, offset.x)
            offset.y = min(point.y, offset.y)
        }
        
        let start = vertex.first!
        moveTo(nil, x: start.x - offset.x, y: start.y - offset.y)
        
        vertex.append(start)
        for i in 1..<vertex.count
        {
            addLineTo(nil, x: vertex[i].x - offset.x, y: vertex[i].y - offset.y)
        }
        
        return self
    }
    
    func grid(row:Int, column:Int, size:CGSize)->CGPath
    {
        for r in 0...row
        {
            let y = CGFloat(r) * size.height
            moveTo(nil, x: 0.0, y: y)
            addLineTo(nil, x: size.width * CGFloat(column), y: y)
        }
        
        for c in 0...column
        {
            let x = CGFloat(c) * size.width
            moveTo(nil, x: x, y: 0.0)
            addLineTo(nil, x: x, y: size.height * CGFloat(row))
        }
        
        return self
    }
}
