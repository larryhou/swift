//
//  RootViewController.swift
//  ViewOrientation
//
//  Created by larryhou on 14/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

extension CGPoint
{
    var vector:CGVector {
        return CGVector(dx: self.x, dy: self.y)
    }
    
    var magnitude:CGFloat
    {
        return sqrt(x*x + y*y)
    }
    
    var description:String
    {
        return String(format: "x:%9.3f, y:%9.3f length:%4.0f", x, y, magnitude)
    }
}

class RootViewController: UITabBarController
{
    override var shouldAutorotate: Bool {return false}
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {return .portrait }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {return .all}
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator)
    {
        print(self, #function)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        print(self, #function, size)
    }
}
