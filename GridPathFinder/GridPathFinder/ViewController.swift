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

class ViewController: UIViewController, MazeNodeUIDelegate
{
    let camera = SKCameraNode()
    var dragrect = CGRect()

    @IBOutlet weak var timeCostLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let view = self.view as! SKView
        view.showsFPS = true
        view.showsDrawCount = true
        view.showsNodeCount = true
        view.showsQuadCount = true
        if #available(iOS 10.0, *)
        {
            print(view.preferredFramesPerSecond)
        }
        else
        {
            // Fallback on earlier versions
        }
        
        let length = 20, row = 51, column = 51
        
        let scene = MazeScene(size: view.frame.size)
        scene.backgroundColor = UIColor.white()
        scene.scaleMode = .aspectFill
        scene.camera = camera
        camera.position = CGPoint(x: view.frame.width / 2, y: view.frame.height / 2)
        view.presentScene(scene)
        scene.addChild(camera)
        
        dragrect.size = CGSize(width:max(0, CGFloat(length * column) - view.frame.width),
                               height:max(0, CGFloat(length * row) - view.frame.height))
        dragrect.origin = camera.position
        dragrect.insetInPlace(dx: -10, dy: -10)
        
        let path = CGMutablePath()
        for r in 0...row
        {
            path.moveTo(nil, x: 0.0, y: CGFloat(r * length))
            path.addLineTo(nil, x: CGFloat(column * length), y: CGFloat(r * length))
        }
        
        for c in 0...column
        {
            path.moveTo(nil, x: CGFloat(c * length), y: 0.0)
            path.addLineTo(nil, x: CGFloat(c * length), y: CGFloat(row * length))
        }
        
        let maze = MazeNode(width: Int32(column), height: Int32(row), length: Int32(length))
        maze.delegate = self
        scene.addChild(maze)
        maze.name = "maze"
        maze.generate()
        
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
        tap2t.numberOfTouchesRequired = 2
        tap2t.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap2t)
    }
    
    func maze(_ maze: MazeNode, graph: GKGridGraph<GKGridGraphNode>, elapse: TimeInterval)
    {
        timeCostLabel.text = String(format: "%.1fms", elapse * 1000)
    }
    
    func maze(_ maze: MazeNode, related: MazeCellNode, focusCameraAt point: CGPoint)
    {
        if let scene = (self.view as! SKView).scene
        {
            let size = scene.size
            let origin = CGPoint(x: camera.position.x - size.width / 2, y: camera.position.y - size.height / 2)
            let frame = CGRect(origin: origin, size: size)

            if frame.contains(point) == false
            {
                let x = clamp(point.x, min: dragrect.minX, max: dragrect.maxX)
                let y = clamp(point.y, min: dragrect.minY, max: dragrect.maxY)
                
                let key = "moveto"
                camera.removeAction(forKey: key)
                camera.run(SKAction.move(to: CGPoint(x:x, y:y), duration: 0.5), withKey: key)
            }
        }
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
                    if let scene = scene as? MazeScene
                    {
                        scene.endnodes.removeAll()
                    }
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

