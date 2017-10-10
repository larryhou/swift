//
//  ViewController.swift
//  VisionPower
//
//  Created by larryhou on 04/09/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import UIKit

class MainViewController: UITabBarController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        UIBarButtonItem.appearance().setTitleTextAttributes([.font:UIFont.systemFont(ofSize: 20, weight: .light)], for: .normal)
        UINavigationBar.appearance().titleTextAttributes = [.font:UIFont.systemFont(ofSize: 30, weight: .thin)]
        UITabBarItem.appearance().setTitleTextAttributes([.font:UIFont.systemFont(ofSize: 20, weight: .light)], for:.normal)
        UITabBarItem.appearance().titlePositionAdjustment.vertical = -10
        
        if let controller = storyboard?.instantiateViewController(withIdentifier: "CameraViewController") as? CameraViewController
        {
            print(controller.view)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {return .portrait}

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

