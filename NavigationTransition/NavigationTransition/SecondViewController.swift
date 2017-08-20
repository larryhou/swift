//
//  SecondViewController.swift
//  ViewOrientation
//
//  Created by larryhou on 14/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panUpdate(_:)))
        view.addGestureRecognizer(pan)
    }
    
    @objc func panUpdate(_ sender:UIPanGestureRecognizer)
    {
        if sender.state == .changed
        {
            let velocity = sender.velocity(in: view)
            print(velocity.description)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

