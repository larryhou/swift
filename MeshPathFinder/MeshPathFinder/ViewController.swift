//
//  ViewController.swift
//  MeshPathFinder
//
//  Created by larryhou on 7/26/16.
//  Copyright © 2016 larryhou. All rights reserved.
//

import UIKit
import GameplayKit
import SpriteKit

func clamp(_ value:CGFloat, min:CGFloat, max:CGFloat)->CGFloat
{
    if value < min
    {
        return min
    }
    
    if value > max
    {
        return max
    }
    return value
}

class ViewController: UIViewController
{
    
    var dragrect = CGRect()
    let camera = SKCameraNode()
    var obstacles:[SKShapeNode] = []

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let view = self.view as! SKView
        view.showsNodeCount = true
        view.showsFPS = true
        
        let scene = SKScene(size: view.frame.size)
        scene.backgroundColor = UIColor.white()
        scene.camera = camera
        scene.addChild(camera)
        view.presentScene(scene)
        
        camera.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        
        let row = 20, column = 20, sidelen:CGFloat = 100, margin:CGFloat = 20
        let grid = SKShapeNode(path: CGMutablePath().grid(row: row, column: column, size: CGSize(width: sidelen, height: sidelen)))
        grid.strokeColor = UIColor(white: 0.90, alpha: 1.0)
        grid.lineWidth = 0.5
        scene.addChild(grid)
        
        dragrect.size = CGSize(width: max(0.0, CGFloat(column) * sidelen - scene.size.width),
                               height:max(0.0, CGFloat(row) * sidelen - scene.size.height))
        dragrect.origin = camera.position
        
        dragrect.insetInPlace(dx: -margin, dy: -margin)
        
        let shape = SKShapeNode(path: CGMutablePath().polygon(sideCount: 3, dimension: 300, equilateral: false))
        shape.strokeColor = UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        shape.lineWidth = 1.5
        scene.addChild(shape)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPanGestureUpdate(gesture:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        
        let press = UITapGestureRecognizer(target: self, action: #selector(onPressGestureUpdate(gesture:)))
        press.numberOfTouchesRequired = 1
        press.numberOfTapsRequired = 1
        view.addGestureRecognizer(press)
    }
    
    var presstime:TimeInterval = 0
    func onPressGestureUpdate(gesture:UITapGestureRecognizer)
    {
        let point = gesture.location(in: self.view)
        switch gesture.state
        {
            case .began:
                presstime = Date().timeIntervalSince1970
            
            case .ended:
                if Date().timeIntervalSince1970 - presstime > 0.2
                {
                    placeObstacle(at: point)
                }
            
            default:break
        }
    }
    
    func placeObstacle(at:CGPoint)
    {
        let list = [3,4,5,6,7,8,9,10]
        
    }
    
    var camOrigin = CGPoint()
    var gesOrigin = CGPoint()
    func onPanGestureUpdate(gesture:UIPanGestureRecognizer)
    {
        let point = gesture.location(in: self.view)
        
        switch gesture.state
        {
            case .began:
                gesOrigin = point
                camOrigin = camera.position
            
            case .changed:
                let dx = point.x - gesOrigin.x
                let dy = point.y - gesOrigin.y
                
                var position = camera.position
                position.x = clamp(camOrigin.x - dx, min:dragrect.minX, max:dragrect.maxX)
                position.y = clamp(camOrigin.y + dy, min:dragrect.minY, max:dragrect.maxY)
                camera.position = position
            
            default:
                break
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
    {
        return .portrait
    }
    
    override func prefersStatusBarHidden() -> Bool
    {
        return true
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

