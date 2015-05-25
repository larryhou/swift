//
//  ViewController.swift
//  SpriteKit
//
//  Created by larryhou on 5/18/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController, XMLReaderDelegate
{
    private var _actions:[NinjaActionInfo]!
    
    private var _scene:SKScene!
    private var _ninja:NinjaPresenter!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        var skView = SKView(frame: self.view.frame)
        skView.frameInterval = 2
        skView.showsNodeCount = true
        skView.showsFPS = true
        
        _scene = SKScene(size: skView.frame.size)
        _scene.backgroundColor = UIColor.grayColor()
        _scene.anchorPoint = CGPointMake(0.5, 0.5)
        _scene.scaleMode = SKSceneScaleMode.ResizeFill
        skView.presentScene(_scene)
        
        self.view.addSubview(skView)

        let url = NSBundle.mainBundle().URLForResource("ninja", withExtension: "xml")
        if url != nil
        {
            XMLReader().read(NSData(contentsOfURL: url!)!, delegate: self)
        }
        
        var tap:UITapGestureRecognizer
        tap = UITapGestureRecognizer()
        tap.addTarget(self, action: "playNextNinjaAction")
        view.addGestureRecognizer(tap)
        
        tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 2
        tap.addTarget(self, action: "switchToAnotherNinja")
        view.addGestureRecognizer(tap)
    }
    
    func playNextNinjaAction()
    {
        _ninja.playNextAction()
        println("tap")
    }
    
    func switchToAnotherNinja()
    {
        println("doubleTap")
    }
    
    func readerDidFinishDocument(reader: XMLReader, data: NSDictionary, elapse: NSTimeInterval)
    {
        _actions = []
        
        let rawActions = (data.valueForKeyPath("actions.action") as! NSArray)[0] as! NSArray
        for i in 0..<rawActions.count
        {
            let item = rawActions[i] as! NSDictionary
            var action = NinjaActionInfo(index: _actions.count, name: item["name"] as! String)
            action.decode(item)
            
            _actions.append(action)
        }
        
        _ninja = NinjaPresenter(atlas: SKTextureAtlas(named: "ninja"), actionInfos: _actions)
        _ninja.play("A_1hit")
        
        _scene.addChild(_ninja)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}

