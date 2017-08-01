//
//  ViewController.swift
//  Tachograph
//
//  Created by larryhou on 30/6/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import UIKit

class ViewController: UITabBarController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override var prefersStatusBarHidden:Bool { return true }
    
    override var shouldAutorotate: Bool {return false}
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation
    {
        return UIInterfaceOrientation.portrait
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}

