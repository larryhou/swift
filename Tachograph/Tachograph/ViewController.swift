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
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        #if !NATIVE_DEBUG
        AssetManager.shared.removeUserStorage(development: true)
        #endif
        
        UIBarButtonItem.appearance().setTitleTextAttributes([.font:UIFont.systemFont(ofSize: 20, weight: .light)], for: .normal)
        UINavigationBar.appearance().titleTextAttributes = [.font:UIFont.systemFont(ofSize: 30, weight: .thin)]
        
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor(white: 1.0, alpha: 0.75).setFill()
        UIRectFill(CGRect(origin: CGPoint(), size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        UINavigationBar.appearance().setBackgroundImage(image, for:.default)
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

