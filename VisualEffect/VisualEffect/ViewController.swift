//
//  ViewController.swift
//  VisualEffect
//
//  Created by larryhou on 28/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import UIKit

class BlurController:UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panUpdate(sender:)))
        view.addGestureRecognizer(pan)
    }
    
    var fractionComplete = CGFloat.nan
    var dismissAnimator:UIViewPropertyAnimator!
    @objc func panUpdate(sender:UIPanGestureRecognizer)
    {
        switch sender.state
        {
            case .began:
                dismissAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .linear)
                { [unowned self] in
                    self.view.frame.origin.y = self.view.frame.height
//                    self.view.layer.cornerRadius = 20
                }
                dismissAnimator.addCompletion
                { [unowned self] position in
                    if position == .end
                    {
                        self.dismiss(animated: false, completion: nil)
                    }
                    self.fractionComplete = CGFloat.nan
                }
                dismissAnimator.pauseAnimation()
            case .changed:
                if fractionComplete.isNaN {fractionComplete = 0}
                
                let translation = sender.translation(in: view)
                fractionComplete += translation.y / view.frame.height
                fractionComplete = min(1, max(0, fractionComplete))
                dismissAnimator.fractionComplete = fractionComplete
                sender.setTranslation(CGPoint.zero, in: view)
            default:
                if dismissAnimator.fractionComplete <= 0.25
                {
                    dismissAnimator.isReversed = true
                }
                dismissAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 1.0)
        }
    }
}


class ViewController: UIViewController
{

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

