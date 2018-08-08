//
//  ViewController.swift
//  SpriteKit
//
//  Created by larryhou on 5/18/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController, XMLReaderDelegate {
    private var _actions: [NinjaActionInfo]!

    private var _scene: SKScene!
    private var _ninja: NinjaPresenter!

    private var _assets: [String]!
    private var _index: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        var skView = SKView(frame: self.view.frame)
        skView.frameInterval = 2
        skView.showsNodeCount = true
        skView.showsFPS = true

        _scene = SKScene(size: skView.frame.size)
        _scene.backgroundColor = UIColor.grayColor()
        _scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        _scene.scaleMode = SKSceneScaleMode.ResizeFill
        skView.presentScene(_scene)

        _assets = ["10000101", "10000201", "10000301", "10000501", "11000141", "11000171"]
        _index = 0

        self.view.addSubview(skView)

        var tap: UITapGestureRecognizer
        tap = UITapGestureRecognizer()
        tap.addTarget(self, action: "playNextNinjaAction")
        view.addGestureRecognizer(tap)

        tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 2
        tap.addTarget(self, action: "changeToAnotherNinja")
        view.addGestureRecognizer(tap)

        changeToAnotherNinja()
    }

    func playNextNinjaAction() {
        _ninja.playNextAction()
    }

    func changeToAnotherNinja() {
        let url = NSBundle.mainBundle().URLForResource(_assets[_index], withExtension: "xml")
        if url != nil {
            XMLReader().read(NSData(contentsOfURL: url!)!, delegate: self)
        }

        _index++
    }

    func readerDidFinishDocument(reader: XMLReader, data: NSDictionary, elapse: NSTimeInterval) {
        _actions = []

        let rawActions = (data.valueForKeyPath("actions.action") as! NSArray)[0] as! NSArray
        for i in 0..<rawActions.count {
            let item = rawActions[i] as! NSDictionary
            var action = NinjaActionInfo(index: _actions.count, name: item["name"] as! String)
            action.decode(item)

            _actions.append(action)
        }

        if _ninja != nil {
            _ninja.removeAllChildren()
            _ninja.removeFromParent()
            _ninja = nil
        }

        _ninja = NinjaPresenter(atlas: SKTextureAtlas(named: _assets[_index]), actionInfos: _actions)
        _ninja.play(_actions[0].name)

        _scene.addChild(_ninja)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
