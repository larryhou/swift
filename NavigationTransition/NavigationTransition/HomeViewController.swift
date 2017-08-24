//
//  HomeViewController.swift
//  ViewOrientation
//
//  Created by larryhou on 15/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit

class HomeViewController: UITableViewController
{
    
}

class ImagePreviewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
}
