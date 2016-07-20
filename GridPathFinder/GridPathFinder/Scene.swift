//
//  Scene.swift
//  GridPathFinder
//
//  Created by larryhou on 20/7/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation
import SpriteKit

class MazeScene:SKScene
{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let maze = childNode(withName: "maze") else
        {
            return
        }
        
        if let touch = touches.first
        {
            let point = touch.location(in: self)
            if let node = maze.nodes(at: point).first as? MazeCellNode
            {
                print("touch x:\(node.gridpos.x) y:\(node.gridpos.y) color:\(node.color)")
                if node.state == .road
                {
                    print("match")
                    node.state = .start
                }
            }
        }
    }
}
