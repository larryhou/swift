//
//  Scene.swift
//  GridPathFinder
//
//  Created by larryhou on 20/7/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit

class MazeScene: SKScene {
    var endnodes: [MazeCellNode] = []
    var timestamp: TimeInterval = 0

    convenience init(size: CGSize, graph: GKGridGraph<GKGridGraphNode>) {
        self.init(size: size)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if event!.timestamp - timestamp < 0.3 {
            return
        }

        guard let maze = childNode(withName: "maze") as? MazeNode else {
            return
        }

        if let touch = touches.first {
            let point = touch.location(in: self)
            if let node = maze.nodes(at: point).first as? MazeCellNode {
                if node.state == .road {
                    switch endnodes.count {
                        case 0:
                            node.stateUpdate(.start)
                            endnodes.append(node)
                        default:
                            node.stateUpdate(.close)
                            endnodes.append(node)
                            while endnodes.count > 2 {
                                endnodes.removeFirst().stateUpdate(.road)
                            }
                            endnodes.first?.stateUpdate(.start)
                            maze.find(from: endnodes[0].gridpos, to: endnodes[1].gridpos)
                    }
                }

            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        timestamp = event!.timestamp
    }
}
