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
    
    func polygon(sideCount count:Int, dimension:CGFloat, equilateral:Bool = false, centerAtOrigin:Bool = true)->CGPath
    {
        let radius = dimension * 0.5
        var vertex:[(x:CGFloat, y:CGFloat)] = [], offset = CGPoint()
        
        let data = randomPolygonVertexAngles(sideCount: count, equilateral: equilateral, repeatCount:5)
        for i in 0..<count
        {
            let angle = data.vertex[i]
            let point = (x:radius * sin(angle), y:radius * cos(angle))
            vertex.append(point)
            
            if !centerAtOrigin
            {
                offset.x = min(point.x, offset.x)
                offset.y = min(point.y, offset.y)
            }
        }
        
        let start = vertex[0]
        moveTo(nil, x: start.x - offset.x, y: start.y - offset.y)
        
        vertex.append(start)
        for i in 1..<vertex.count
        {
            addLineTo(nil, x: vertex[i].x - offset.x, y: vertex[i].y - offset.y)
        }
        
        return self
    }
    
    func randomPolygonVertexAngles(sideCount:Int, equilateral:Bool = false, repeatCount:Int = 1)->(vertex:[CGFloat], area:CGFloat)
    {
        let repeatCount = equilateral ? 1 : repeatCount
        let total = CGFloat.pi * 2, delta = total / CGFloat(sideCount)
        
        var maxArea:CGFloat = 0.0, vertex:[CGFloat] = Array(repeating: 0.0, count: sideCount)
        
        for _ in 0..<repeatCount
        {
            var parts:[CGFloat] = [], divider:CGFloat = 0.0
            for _ in 0..<sideCount
            {
                let num = CGFloat(GKRandomSource.sharedRandom().nextInt(withUpperBound: 0xFF))
                parts.append(num)
                divider += num
            }
            
            var area:CGFloat = 0.0, sum:CGFloat = 0.0
            for i in 1...sideCount
            {
                let angle:CGFloat
                if i == sideCount
                {
                    angle = total - sum
                }
                else
                {
                    if !equilateral
                    {
                        angle = total * parts[i - 1] / divider
                    }
                    else
                    {
                        angle = delta
                    }
                }
                
                area += sin(angle / 2) * cos(angle / 2)
                sum += angle
                
                parts[i - 1] = sum
            }
            
            if area > maxArea
            {
                vertex = parts
                maxArea = area
            }
        }
        
        return (vertex, maxArea)
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
