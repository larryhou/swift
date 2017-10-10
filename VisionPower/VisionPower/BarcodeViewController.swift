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
        
        view.insertSubview(snapshotController!.view, at: 0)
    }
}
