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

extension Array
{
    mutating func shuffleInPlace()
    {
        for i in 0..<count
        {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else
            {
                continue
            }
            
            swap(&self[i], &self[j])
        }
    }
    
    func shuffle()->[Element]
    {
        var ret:[Element] = self
        for i in 0..<count
        {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else
            {
                continue
            }
            
            swap(&ret[i], &ret[j])
        }
        
        return ret
    }
    
    func random()->Element
    {
        let index = arc4random_uniform(UInt32(count))
        return self[Int(index)]
    }
}

class ViewController: UIViewController, UIGestureRecognizerDelegate
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
        scene.backgroundColor = UIColor.white
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
        dragrect = dragrect.insetBy(dx: -margin, dy: -margin)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPanGestureUpdate(gesture:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        
        let press = UILongPressGestureRecognizer(target: self, action: #selector(onPressGestureUpdate(gesture:)))
        press.numberOfTouchesRequired = 1
        press.numberOfTapsRequired = 1
//        press.minimumPressDuration = 0.2
//        press.allowableMovement = 5.0
        view.addGestureRecognizer(press)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapGestureUpdate(gesture:)))
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap)
    }
    
    func onTapGestureUpdate(gesture:UITapGestureRecognizer)
    {
        print("tap", gesture.state, gesture.state.rawValue)
    }
    
    var presstime:TimeInterval = 0
    func onPressGestureUpdate(gesture:UILongPressGestureRecognizer)
    {
        let point = gesture.location(in: self.view)
        print(gesture.state, gesture.state.rawValue)
        
        switch gesture.state
        {
            case .began:
                presstime = Date().timeIntervalSince1970
                print("began", presstime)
                break
            
            case .ended:
                if Date().timeIntervalSince1970 - presstime > 0.5
                {
                    placeObstacle(at: point)
                    print("recognized", Date().timeIntervalSince1970)
                }
                break
            
            default:break
        }
    }
    
    func placeObstacle(at position:CGPoint)
    {
        let sideCount = [3,4,5,6,7,8,9,10].random()
        let dimension = [50,100,150,200,250,300].random()
        let shape = SKShapeNode(path: CGMutablePath().polygon(sideCount: sideCount, dimension: CGFloat(dimension)))
        shape.fillColor = [UIColor.black, UIColor.blue, UIColor.brown, UIColor.cyan, UIColor.red, UIColor.yellow, UIColor.green, UIColor.darkGray, UIColor.gray, UIColor.orange, UIColor.purple].random()
        shape.strokeColor = UIColor.clear
        shape.isAntialiased = true
        
        if let scene = (view as? SKView)?.scene
        {
            shape.position = scene.convertPoint(fromView: position)
            scene.addChild(shape)
        }
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
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask
    {
        return .portrait
    }
    
    override var prefersStatusBarHidden:Bool
    {
        return true
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

