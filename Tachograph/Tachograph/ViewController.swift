//
//  ViewController.swift
//  Tachograph
//
//  Created by larryhou on 30/6/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CameraModelDelegate
{
    func model(assets: [CameraModel.CameraAsset], type: CameraModel.AssetType)
    {
        
    }
    
    func model(command: RemoteCommand, data: Codable)
    {
        if command == .fetchToken
        {
            model.fetchVersion()
            model.query(type: "app_status")
            model.query(type: "date_time")
            model.fetchStorage()
        }
        else if command == .fetchImages
        {
            model.captureImage()
        }
    }
    
    func model(ready: Bool)
    {
        model.fetchRouteVideos()
        model.fetchEventVideos()
        model.fetchImages()
    }
    
    var model:CameraModel!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        model = CameraModel.shared
        model.delegate = self
        
        model.fetchToken()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}

