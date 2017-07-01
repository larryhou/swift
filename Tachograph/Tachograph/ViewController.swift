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
    func model(command: RemoteCommand, data: RemoteMessage)
    {
        if command == .fetchToken
        {
            model.fetchVersion()
            model.fetchHierarchy()
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

