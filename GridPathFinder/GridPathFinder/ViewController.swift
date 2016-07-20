//
//  ViewController.swift
//  GridPathFinder
//
//  Created by larryhou on 18/7/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

extension SKNode
{
    convenience init(name:String)
    {
        self.init()
        self.name = name
    }
}

func clamp(_ x:CGFloat, min:CGFloat, max:CGFloat) -> CGFloat
{
    if x > max
    {
        return max
    }
    
    if x < min
    {
        return min
    }
    
    return x
}

class ViewController: UIViewController
{
    let camera = SKCameraNode()
    var dragrect = CGRect()

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let view = self.view as! SKView
        view.showsFPS = true
        view.showsDrawCount = true
        view.showsNodeCount = true
        view.showsQuadCount = true
        print(view.preferredFramesPerSecond)
        
        let scene = SKScene(size: view.frame.size)
        scene.backgroundColor = UIColor.white()
        scene.scaleMode = .aspectFill
        scene.camera = camera
        camera.position = CGPoint(x: view.frame.width / 2, y: view.frame.height / 2)
        view.presentScene(scene)
        
        let size = 20, row = 51, column = 51
        dragrect.size = CGSize(width:max(0, CGFloat(size * column) - view.frame.width),
                               height:max(0, CGFloat(size * row) - view.frame.height))
        dragrect.origin = camera.position
        dragrect.insetInPlace(dx: -10, dy: -10)
        
        let path = CGMutablePath()
        for r in 0...row
        {
            path.moveTo(nil, x: 0.0, y: CGFloat(r * size))
            path.addLineTo(nil, x: CGFloat(column * size), y: CGFloat(r * size))
        }
        
        for c in 0...column
        {
            path.moveTo(nil, x: CGFloat(c * size), y: 0.0)
            path.addLineTo(nil, x: CGFloat(c * size), y: CGFloat(row * size))
        }
        
        let maze = MazeNode(width: Int32(column), height: Int32(row), length: Int32(size))
        scene.addChild(maze)
        maze.name = "maze"
        maze.generate()
        
        let graph = GKGridGraph(fromGridStartingAt: vector_int2(0,0), width: Int32(column), height: Int32(row), diagonalsAllowed: false)
        print(graph.node(atGridPosition: vector_int2(1,1)))
        
        let grid = SKShapeNode(path: path, centered: false)
        grid.strokeColor = SKColor(white: 1.0, alpha: 1.0)
        grid.isUserInteractionEnabled = false
        grid.lineWidth = 1.5
        scene.addChild(grid)
        
        print(scene.size, view.frame,UIScreen.main().bounds, UIScreen.main().scale)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(OnPanGestureUpdate))
        pan.maximumNumberOfTouches = 1
        pan.minimumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        
        let tap2t = UITapGestureRecognizer(target: self, action: #selector(OnTapGestureUpdate))
        tap2t.numberOfTouchesRequired = 1
        tap2t.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap2t)
        
        
    }
    
    func OnTapGestureUpdate(sender:UITapGestureRecognizer)
    {
        if sender.state == .ended
        {
            if let scene = (self.view as! SKView).scene
            {
                if let maze = scene.childNode(withName: "maze") as? MazeNode
                {
                    maze.generate()
                }
            }
        }
    }
    
    private var gesOrigin = CGPoint()
    private var camOrigin = CGPoint()
    func OnPanGestureUpdate(sender:UIPanGestureRecognizer)
    {
        let point = sender.location(in: view)
        switch sender.state
        {
            case .began:
                gesOrigin.x = point.x
                gesOrigin.y = point.y
                
                camOrigin.x = camera.position.x
                camOrigin.y = camera.position.y
            
            case .changed:
                let dx = point.x - gesOrigin.x
                let dy = point.y - gesOrigin.y
                
                var position = camera.position
                position.x = clamp(camOrigin.x - dx,min: dragrect.minX, max: dragrect.maxX)
                position.y = clamp(camOrigin.y + dy,min: dragrect.minY, max: dragrect.maxY)
                camera.position = position
            default:break
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    override func prefersStatusBarHidden() -> Bool
    {
        return true
    }
}

