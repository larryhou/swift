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

class InteractiveNavigationController : UINavigationController
{
    var transitionController:NavigationTransitionController!
    
    override func loadView()
    {
        super.loadView()
        transitionController = SwipeVerticalTransitionController(navigationController: self, duration: 0.5)
    }
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
