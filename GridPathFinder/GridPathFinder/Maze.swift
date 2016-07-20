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

class Array2D<Element> where Element:Equatable
{
    var width:Int32, height:Int32
    private var map:[Int32:Element]
    
    init(width:Int32, height:Int32)
    {
        self.width = width;self.height = height;
        self.map = [:]
    }
    
    convenience init()
    {
        self.init(width: Int32.max, height: Int32.max)
    }
    
    func resize(width:Int32, height:Int32)
    {
        map.removeAll()
        self.width = width; self.height = height;
    }
    
    subscript(_ vec:vector_int2)->Element?
    {
        get
        {
            return self[vec.x, vec.y]
        }
        
        set
        {
            self[vec.x, vec.y] = newValue
        }
    }
    
    subscript(_ x:Int32, _ y:Int32)->Element?
    {
        get
        {
            return map[y * width + x]
        }
        
        set
        {
            if x < width && y < height
            {
                map[y * width + x] = newValue
            }
        }
    }
    
    func clear()
    {
        map.removeAll()
    }
}

class MazeAlgorithm
{
    enum ExploreDirection:Int
    {
        case left = 0, down, right, up
        
        static func random()->ExploreDirection
        {
            let value = GKRandomSource.sharedRandom().nextInt(withUpperBound: 4)
            return ExploreDirection(rawValue: value)!
        }
        
        var dx:Int32
        {
            switch self
            {
                case .down,.up: return 0
                case .right: return 2
                case .left: return -2
            }
        }
        
        var dy:Int32
        {
            switch self
            {
                case .left, .right: return 0
                case .down: return -2
                case .up: return 2
            }
        }
    }
    
    var width:Int32 { return walls.width}
    var height:Int32 { return walls.height}
    
    private let walls:Array2D<Bool>
    private let visited:Array2D<Bool>
    private var stack:[vector_int2] = []
    
    init(width:Int32, height:Int32)
    {
        walls = Array2D(width: width, height: height)
        visited = Array2D()
    }
    
    func resize(width:Int32, height:Int32)
    {
        walls.resize(width: width, height: height)
    }
    
    func generate()
    {
        walls.clear()
        for x in 0..<width
        {
            for y in 0..<height
            {
                walls[x, y] = x % 2 == 1 || y % 2 == 1
            }
        }
        
        visited.clear()
        visited[0, 0] = true
        
        stack.removeAll()
        stack.append(int2(x:0, y:0))
        
        explore: while let node = stack.last
        {
            if hasUnvisitedNeighbor(x: node.x, y: node.y) == false
            {
                stack.removeLast()
                continue
            }
            
            while true
            {
                let dir = ExploreDirection.random()
                let next = vector_int2(x: node.x + dir.dx, y: node.y + dir.dy)
                if isUnvistedAt(x: next.x, y: next.y)
                {
                    visited[next] = true
                    walls[next.x + dir.dx / 2, next.y + dir.dy / 2] = false
                    stack.append(next)
                    break explore
                }
            }
        }
    }
    
    //MARK: check node walkable
    subscript(_ x:Int32, _ y:Int32)->Bool
    {
        if let flag = walls[x, y]
        {
            return flag == false
        }
        
        return false
    }
    
    private func hasUnvisitedNeighbor(x:Int32, y:Int32)->Bool
    {
        return isUnvistedAt(x: x - 2, y: y) || isUnvistedAt(x: x + 2, y: y) || isUnvistedAt(x: x, y: y - 2) || isUnvistedAt(x: x, y: y + 2)
    }
    
    private func isUnvistedAt(x:Int32, y:Int32)->Bool
    {
        if walls[x, y] == nil
        {
            return false
        }
        
        return visited[x, y] == false
    }
}
