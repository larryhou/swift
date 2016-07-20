//
//  MapItem.swift
//  GridPathFinder
//
//  Created by larryhou on 7/20/16.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit

class MazeItem:SKSpriteNode, IPoolObject
{
    var gridpos = vector_int2()
    
    func awake()
    {
        
    }
    
    func recycle()
    {
        if self.parent != nil
        {
            removeFromParent()
        }
    }
}

class Maze:SKNode
{
    var length:Int32 = 0
    var algorithm = MazeAlgorithm(width: 10, height: 10)
    let pool = ObjectPool<MazeItem>()
    var map:[Int32:MazeItem] = [:]
    
    convenience init(width:Int32, height:Int32, length:Int32 = 10)
    {
        self.init()
        
        self.length = length
        self.map = [:]
        
        resize(width: width, height: height)
    }
    
    func resize(width:Int32, height:Int32)
    {
        algorithm.resize(width: width, height: height)
        
        children.forEach
        {
            if let item = $0 as? MazeItem
            {
                pool.recycle(item)
            }
        }
        
        for y in 0..<algorithm.height
        {
            for x in 0..<algorithm.width
            {
                let item = pool.get()
                item.size = CGSize(width: Int(length), height: Int(length))
                item.color = GridColors.default
                item.anchorPoint = CGPoint.zero
                item.position = CGPoint(x: Int(x * length), y: Int(y * length))
                item.gridpos.x = x
                item.gridpos.y = y
                addChild(item)
                
                map[y * algorithm.width + x] = item
            }
        }
    }
    
    func generate()
    {
        algorithm.generate()
        for y in 0..<algorithm.height
        {
            for x in 0..<algorithm.width
            {
                if let item = map[y * algorithm.width + x]
                {
                    let enabled = algorithm[x, y]
                    item.color = enabled ? GridColors.road : GridColors.wall
                    item.isUserInteractionEnabled = enabled
                }
            }
        }
    }
}

class MazeAlgorithm
{
    var width:Int32, height:Int32
    
    private var map:[Int32:Bool]
    
    init(width:Int32, height:Int32)
    {
        self.width = width
        self.height = height
        self.map = [:]
    }
    
    func resize(width:Int32, height:Int32)
    {
        self.width = width
        self.height = height
        self.map.removeAll()
    }
    
    func generate()
    {
        map.removeAll()
        for x in 0..<width
        {
            for y in 0..<height
            {
                map[y * width + x] = x % 2 == 1 || y % 2 == 1
            }
        }
    }
    
    //MARK: check node walkable
    subscript(_ x:Int32, _ y:Int32)->Bool
    {
        if let flag = map[y * width + x]
        {
            return flag == false
        }
        
        return false
    }
}
