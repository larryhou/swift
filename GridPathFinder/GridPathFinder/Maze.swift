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
    struct GridStateColor
    {
        private static let data:[GridState:UIColor] =
        {
            var dict:[GridState:UIColor] = [:]
            dict[.blank] = UIColor(white: 0.95, alpha: 1.0)
            dict[.wall]  = UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
            dict[.road]  = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 0.3)
            dict[.path]  = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
            dict[.start] = UIColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 1.0)
            dict[.close] = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            return dict
        }()
    }
    
    case blank, wall, road, path, start, close
    
    var color:UIColor
    {
        if let value = GridStateColor.data[self]
        {
            return value
        }
        
        return GridStateColor.data[.blank]!
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        print("touch cell")
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

protocol MazeNodeUIDelegate
{
    func maze(_ maze:MazeNode, graph:GKGridGraph<GKGridGraphNode>, elapse:TimeInterval)
    func maze(_ maze:MazeNode, related:MazeCellNode, focusCameraAt:CGPoint)
}

class MazeNode:SKNode
{
    private var length:Int32 = 0
    private var algorithm = MazeAlgorithm(width: 10, height: 10)
    private let map = Array2D<MazeCellNode>(width:10, height: 10)
    private let pool = ObjectPool<MazeCellNode>()
    private var cache:[MazeCellNode] = []
    
    var graph:GKGridGraph<GKGridGraphNode>?
    var delegate:MazeNodeUIDelegate?
    
    convenience init(width:Int32, height:Int32, length:Int32 = 10)
    {
        self.init()

        self.length = length
        resize(width: width, height: height)
    }
    
    func resize(width:Int32, height:Int32)
    {
        algorithm.resize(width: width, height: height)
        graph = GKGridGraph(fromGridStartingAt: int2(0,0), width: algorithm.width, height: algorithm.height, diagonalsAllowed: false)
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
    
    var removedNodes:[GKGridGraphNode] = []
    func generate()
    {
        algorithm.generate()
        graph?.addNodes(removedNodes)
        while removedNodes.count > 0
        {
            graph?.connectNode(toAdjacentNodes: removedNodes.removeLast())
        }
        
        for y in 0..<algorithm.height
        {
            for x in 0..<algorithm.width
            {
                if let item = map[x, y]
                {
                    let enabled = algorithm[x, y]
                    item.state = enabled ? .road : .wall
                    item.isUserInteractionEnabled = enabled
                    if enabled == false
                    {
                        removedNodes.append(graph!.node(atGridPosition: int2(x, y))!)
                    }
                }
            }
        }
        
        graph?.removeNodes(removedNodes)
    }
    
    func find(from:int2, to:int2)
    {
        if let graph = graph
        {
            while cache.count > 0
            {
                cache.removeLast().state = .road
            }
            
            let start = graph.node(atGridPosition: from)!
            let close = graph.node(atGridPosition: to)!
            
            let timestamp = Date().timeIntervalSince1970
            let path = start.findPath(to: close)
            
            delegate?.maze(self, graph: graph, elapse: Date().timeIntervalSince1970 - timestamp)
            
            if path.count > 0
            {
                for i in 1..<path.count-1
                {
                    let pos = (path[i] as! GKGridGraphNode).gridPosition
                    if let cell = map[pos]
                    {
                        cell.state = .path
                        cache.append(cell)
                    }
                    
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
