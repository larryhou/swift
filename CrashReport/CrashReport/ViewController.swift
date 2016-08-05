//
//  ViewController.swift
//  CrashReport
//
//  Created by larryhou on 8/4/16.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation
import UIKit
import GameplayKit

class ViewController:UIViewController
{
    var method:TestMethod = .none
    var bartitle:String = ""
    
    override func viewDidLoad()
    {
        navigationItem.title = bartitle
        
        switch method
        {
            case .null:
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false)
                {_ in
                    let rect:CGRect? = nil
                    print(rect!.width)
                }
                break
            
            case .memory:
                var list:[[UInt8]] = []
                Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true)
                {_ in
                    let bytes = [UInt8](repeating:10, count:1024*1024)
                    list.append(bytes)
                }
                break
            
            case .cpu:
                Timer.scheduledTimer(withTimeInterval: 0.0, repeats: false)
                {_ in
                    self.ruineCPU()
                }
                break
            
            case .abort:
                
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false)
                {_ in
                    abort()
                }
                break
            
            case .none:
                break
        }
    }
    
    func ruineCPU()
    {
        let width:Int32 = 110, height:Int32 = 110
        let graph = GKGridGraph(fromGridStartingAt: int2(0,0), width: width, height: height, diagonalsAllowed: false)
        
        var obstacles:[GKGridGraphNode] = []
        let random = GKRandomSource.sharedRandom()
        for x in 0..<width
        {
            for y in 0..<height
            {
                let densitiy = 5
                if random.nextInt(withUpperBound: densitiy) % densitiy == 1
                {
                    let node = graph.node(atGridPosition: int2(x, y))
                    obstacles.append(node!)
                }
            }
        }
        
        graph.removeNodes(obstacles)
        
        func get_random_node()->GKGraphNode
        {
            let nodes = graph.nodes!
            return nodes[random.nextInt(withUpperBound: nodes.count)]
        }
        
        while true
        {
            let queue = DispatchQueue(label: Date().description, qos: DispatchQoS.default, attributes: DispatchQueue.Attributes.concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.never, target: nil)
            queue.async
            {
                graph.findPath(from: get_random_node(), to: get_random_node())
            }
        }
    }
}
