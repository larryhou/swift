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

enum GridState
{
    case blank, wall, road, path, start, close
    
    var color:UIColor
    {
        switch self
        {
            case .blank: return UIColor(white: 0.95, alpha: 1.0)
            case .wall: return UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
            case .road: return UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 0.3)
            case .path: return UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
            case .start: return UIColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 1.0)
            case .close: return UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        }
    }
}

class MazeCellNode:SKSpriteNode, IPoolObject
{
    var gridpos = vector_int2()
    var state:GridState = .blank
    {
        didSet
        {
            self.color = state.color
        }
    }
    
    func awake()
    {
        self.state = .blank
    }
    
    func recycle()
    {
        if self.parent != nil
        {
            removeFromParent()
        }
    }
}

class MazeNode:SKNode
{
    var length:Int32 = 0
    var algorithm = MazeAlgorithm(width: 10, height: 10)
    let map = Array2D<MazeCellNode>(width:10, height: 10)
    let pool = ObjectPool<MazeCellNode>()
    
    convenience init(width:Int32, height:Int32, length:Int32 = 10)
    {
        self.init()
        
        self.length = length
        resize(width: width, height: height)
    }
    
    func resize(width:Int32, height:Int32)
    {
        algorithm.resize(width: width, height: height)
        map.resize(width: width, height: height)
        
        children.forEach
        {
            if let item = $0 as? MazeCellNode
            {
                pool.recycle(item)
            }
        }
        
        for y in 0..<algorithm.height
        {
            for x in 0..<algorithm.width
            {
                let cell = pool.get()
                cell.size = CGSize(width: Int(length), height: Int(length))
                cell.anchorPoint = CGPoint.zero
                cell.position = CGPoint(x: Int(x * length), y: Int(y * length))
                cell.gridpos.x = x
                cell.gridpos.y = y
                addChild(cell)
                
                map[x, y] = cell
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
                if let item = map[x, y]
                {
                    let enabled = algorithm[x, y]
                    item.state = enabled ? .road : .wall
                    item.isUserInteractionEnabled = enabled
                }
            }
        }
    }
}

class Array2D<Element> where Element:Equatable
{
    var width:Int32, height:Int32
    private var map:[String:Element]
    
    init(width:Int32, height:Int32)
    {
        self.width = width;self.height = height;
        self.map = [:]
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
            return map["\(x):\(y)"]
        }
        
        set
        {
            if x < width && y < height
            {
                map["\(x):\(y)"] = newValue
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
    
    var width:Int32 { return wall.width}
    var height:Int32 { return wall.height}
    
    private let wall:Array2D<Bool>
    
    init(width:Int32, height:Int32)
    {
        wall = Array2D(width: width, height: height)
        visited = Array2D(width: width, height: height)
    }
    
    func resize(width:Int32, height:Int32)
    {
        wall.resize(width: width, height: height)
        visited.resize(width: width, height: height)
    }
    
    private let visited:Array2D<Bool>
    private var search:[int2] = []
    func generate()
    {
        wall.clear()
        for x in 0..<width
        {
            for y in 0..<height
            {
                wall[x, y] = x % 2 == 1 || y % 2 == 1
            }
        }
        
        visited.clear()
        visited[0, 0] = true
        
        search.removeAll()
        search.append(int2(x:0, y:0))
        
        while let node = search.last
        {
            if hasUnvisitedNeighbor(x: node.x, y: node.y) == false
            {
                search.removeLast()
                continue
            }
            
            explore: while true
            {
                let dir = ExploreDirection.random()
                let next = int2(x: node.x + dir.dx, y: node.y + dir.dy)
                
                if isUnvistedAt(x: next.x, y: next.y)
                {
                    visited[next] = true
                    search.append(next)
                    
                    wall[node.x + dir.dx / 2, node.y + dir.dy / 2] = false
                    break explore
                }
            }
        }
    }
    
    //MARK: check node walkable
    subscript(_ x:Int32, _ y:Int32)->Bool
    {
        if let flag = wall[x, y]
        {
            return flag == false
        }
        
        return false
    }
    
    private func hasUnvisitedNeighbor(x:Int32, y:Int32)->Bool
    {
        return
            isUnvistedAt(x: x - 2, y: y) ||
            isUnvistedAt(x: x + 2, y: y) ||
            isUnvistedAt(x: x, y: y - 2) ||
            isUnvistedAt(x: x, y: y + 2)
    }
    
    private func isUnvistedAt(x:Int32, y:Int32)->Bool
    {
        if wall[x, y] == nil
        {
            return false
        }
        
        if let value = visited[x, y]
        {
            return value == false
        }
        
        return true
    }
}
