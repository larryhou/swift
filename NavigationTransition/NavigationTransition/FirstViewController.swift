//
//  FirstViewController.swift
//  ViewOrientation
//
//  Created by larryhou on 14/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
//    override var shouldAutorotate: Bool {return false}
//    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {return .portrait }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator)
    {
        print(self, #function)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        print(self, #function, size)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

