//
//  SwipeVerticalTransitionController.swift
//  NavigationTransition
//
//  Created by larryhou on 24/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit

//NOTE: duration = 0.8
class SwipeVerticalTransitionController: NavigationTransitionController
{
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        let allowed = super.gestureRecognizerShouldBegin(gestureRecognizer)
        if !interactive
        {
            let translation = gesture.translation(in: gesture.view)
            return translation.y > 0 && allowed
        }
        return allowed
    }
    
    override func createTransitionAnimator(transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator
    {
        let fromController = transitionContext.viewController(forKey: .from)!
        let toController = transitionContext.viewController(forKey: .to)!
        
        let fromView = fromController.view!
        let toView = toController.view!
        
        toView.frame = transitionContext.finalFrame(for: toController)
        
        if operation == .push
        {
            transitionContext.containerView.insertSubview(toView, aboveSubview: fromView)
            var frame = toView.frame
            frame.origin.y = frame.height
            toView.frame = frame
            toView.layer.cornerRadius = 20
            toView.backgroundColor = .red
            return UIViewPropertyAnimator(duration: duration, curve: .easeInOut)
            {
                toView.frame.origin.y = 0
                toView.layer.cornerRadius = 0
                toView.backgroundColor = .white
            }
        }
        else
        {
            transitionContext.containerView.insertSubview(toView, belowSubview: fromView)
            var frame = fromView.frame
            frame.origin.y = frame.height
            return UIViewPropertyAnimator(duration: duration, curve: .easeInOut)
            {
                fromView.frame = frame
                fromView.layer.cornerRadius = 20
                fromView.backgroundColor = .red
            }
        }
    }
    
    override func fraction(of translation: CGPoint) -> CGFloat
    {
        return super.fraction(of: translation) / 4
    }
    
    override func interactionUpdate(with translation: CGPoint)
    {
        super.interactionUpdate(with: translation)
    }
    
    override func updateInteractiveTransition(_ percentComplete: CGFloat, with translation: CGPoint)
    {
        
    }
    
    override func createRecoverAnimator() -> UIViewPropertyAnimator?
    {
        return nil
    }
}
