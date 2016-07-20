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

public struct GridColors
{
    static public let `default` = UIColor(white: 0.95, alpha: 1.0)
    static public let wall = UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
    static public let road = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
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
        
        let size = 20, row = 50, column = 40
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
        
        let content = Maze(width: Int32(column), height: Int32(row), length: Int32(size))
        scene.addChild(content)
        content.generate()
        
        let graph = GKGridGraph(fromGridStartingAt: vector_int2(0,0), width: Int32(column), height: Int32(row), diagonalsAllowed: false)
        print(graph.node(atGridPosition: vector_int2(1,1)))
        
        let grid = SKShapeNode(path: path, centered: false)
        grid.strokeColor = SKColor(white: 1.0, alpha: 1.0)
        grid.isUserInteractionEnabled = false
        grid.lineWidth = 1.5
        scene.addChild(grid)
        
        print(scene.size, view.frame,UIScreen.main().bounds, UIScreen.main().scale)
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(OnPanGestureUpdate))
        gesture.maximumNumberOfTouches = 1
        gesture.minimumNumberOfTouches = 1
        view.addGestureRecognizer(gesture)
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
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool
    {
        return true
    }
}

