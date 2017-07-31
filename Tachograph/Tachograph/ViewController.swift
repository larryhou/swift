//
//  ViewController.swift
//  Tachograph
//
//  Created by larryhou on 30/6/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import UIKit

protocol ModelObserver
{
    func model(assets: [CameraModel.CameraAsset], type: CameraModel.AssetType)
    func model(update: CameraModel.CameraAsset, type: CameraModel.AssetType)
}

class ViewController: UITabBarController, CameraModelDelegate
{
    func model(update: CameraModel.CameraAsset, type: CameraModel.AssetType)
    {
        if let viewControllers = self.viewControllers
        {
            for item in viewControllers
            {
                if item is ModelObserver
                {
                    (item as! ModelObserver).model(update: update, type: type)
                }
            }
        }
    }
    
    func model(assets: [CameraModel.CameraAsset], type: CameraModel.AssetType)
    {
        if let viewControllers = self.viewControllers
        {
            for item in viewControllers
            {
                if item is ModelObserver
                {
                    (item as! ModelObserver).model(assets: assets, type: type)
                }
            }
        }
    }
    
    func model(command: RemoteCommand, data: Codable)
    {
        
    }
    
    var model:CameraModel!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        model = CameraModel.shared
        model.delegate = self
    }
    
    override var prefersStatusBarHidden:Bool { return true }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation
    {
        return UIInterfaceOrientation.portrait
    }
    
    override var shouldAutorotate: Bool {return false}

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }    
}

