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

class ViewController: UIViewController
{
    
    var dragrect = CGRect()

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let view = self.view as! SKView
        view.showsNodeCount = true
        view.showsFPS = true
        
        let scene = SKScene(size: view.frame.size)
        scene.backgroundColor = UIColor.white()
        view.presentScene(scene)
        
        let row = 100, column = 100, sidelen:CGFloat = 50, margin:CGFloat = 20
        let grid = SKShapeNode(path: CGMutablePath().grid(row: row, column: column, size: CGSize(width: sidelen, height: sidelen)))
        grid.strokeColor = UIColor(white: 0.95, alpha: 1.0)
        grid.lineWidth = 0.5
        scene.addChild(grid)
        
        dragrect.size = CGSize(width: max(0.0, CGFloat(column) * sidelen - scene.size.width),
                               height:max(0.0, CGFloat(row) * sidelen - scene.size.height))
        dragrect.insetBy(dx: -margin, dy: -margin)
        
        let shape = SKShapeNode(path: CGMutablePath().polygon(sideCount: 3, dimension: 300, equilateral: false))
        shape.strokeColor = UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        shape.lineWidth = 1.5
        scene.addChild(shape)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPanGestureUpdate))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
    }
    
    var cameraRefer = CGPoint()
    var gestureRefer = CGPoint()
    func onPanGestureUpdate(gesture:UIPanGestureRecognizer)
    {
        switch gesture.state
        {
            case .began:
                break
            
            case .changed:
                break
            
            default:
                break
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
    {
        return .portrait
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

