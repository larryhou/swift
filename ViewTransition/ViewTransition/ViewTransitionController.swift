//
//  ViewTransitionController.swift
//  ViewTransition
//
//  Created by larryhou on 25/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit

class ViewTransitionController: UIViewController
{
    var options:UIViewAnimationOptions = []
    
    var fromView:UIImageView!
    var toView:UIImageView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        fromView = UIImageView(image: UIImage(named: "src"))
        fromView.frame = view.frame
        view.addSubview(fromView)
        
        toView = UIImageView(image: UIImage(named: "dst"))
        toView.frame = view.frame
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panUpdate(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
    }
    
    var fractionComplete = CGFloat.nan
    var animator:UIViewPropertyAnimator!
    @objc func panUpdate(_ sender:UIPanGestureRecognizer)
    {
        let translation = sender.translation(in: view)
        switch sender.state
        {
            case .began:
                animator = UIViewPropertyAnimator(duration: 0.2, curve: .linear)
                { [unowned self] in
                    self.view.frame.origin.y = self.view.frame.height
                }
                animator.addCompletion
                { position in
                    if position == .end
                    {
                        self.dismiss(animated: false, completion: nil)
                    }
                    self.fractionComplete = CGFloat.nan
                }
                animator.pauseAnimation()
                fallthrough
            case .changed:
                if fractionComplete.isNaN {fractionComplete = 0}
                fractionComplete = fractionComplete + translation.y/view.frame.height
                fractionComplete = min(1, max(0, fractionComplete))
                animator.fractionComplete = fractionComplete
                sender.setTranslation(CGPoint.zero, in: view)
            default:
                if animator.fractionComplete <= 0.25
                {
                    animator.isReversed = true
                }
                print("fraction", fractionComplete)
                animator.continueAnimation(withTimingParameters: nil, durationFactor: 1.0)
        }
    }
    
    func startAnimation()
    {
        view.addSubview(toView)
        UIView.transition(from: fromView, to: toView, duration: 1.0, options: options)
    }
}
