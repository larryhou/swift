//
//  BarcodeViewController.swift
//  VisionPower
//
//  Created by larryhou on 06/09/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit

class BarcodeViewController: UIViewController
{
    var snapshotController:PhotoViewController?
    var cameraController:CameraViewController?
    
    var currentController:UIViewController!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let controller = storyboard?.instantiateViewController(withIdentifier: "CameraViewController") as? CameraViewController
        {
            self.cameraController = controller
            addChildViewController(controller)
        }
        
        if let controller = storyboard?.instantiateViewController(withIdentifier: "PhotoViewController") as? PhotoViewController
        {
            self.snapshotController = controller
            addChildViewController(controller)
        }
        
        currentController = snapshotController!
        
        view.insertSubview(currentController.view, at: 0)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(switchInputMode(_:)))
        view.addGestureRecognizer(pan)
    }
    
    @objc func switchInputMode(_ sender:UIPanGestureRecognizer)
    {
        guard sender.state == .began else {return}
        
        let options:UIViewAnimationOptions
        let translation = sender.translation(in: view)
        
        if abs(translation.x) > abs(translation.y)
        {
            if translation.x > 0
            {
                options = .transitionFlipFromLeft
            }
            else
            {
                options = .transitionFlipFromRight
            }
        }
        else
        {
            if translation.y > 0
            {
                options = .transitionFlipFromBottom
            }
            else
            {
                options = .transitionFlipFromTop
            }
        }
        
        let toController:UIViewController
        if currentController == snapshotController
        {
            toController = cameraController!
        }
        else
        {
            toController = snapshotController!
        }
        
        transition(from: currentController, to: toController, duration: 1, options: options, animations:
        { [unowned self] in
            self.view.addSubview(toController.view)
            self.currentController.view.removeFromSuperview()
        })
        { [unowned self] (success) in
            if success
            {
                self.currentController = toController
            }
        }
    }
}
