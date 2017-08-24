//
//  SwipeVerticalTransitionController.swift
//  NavigationTransition
//
//  Created by larryhou on 24/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit

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
        if operation == .push
        {
            return super.createTransitionAnimator(transitionContext: transitionContext)
        }
        
        let fromController = transitionContext.viewController(forKey: .from)!
        let toController = transitionContext.viewController(forKey: .to)!
        
        let fromView = fromController.view!
        let toView = toController.view!
        
        toView.frame = transitionContext.finalFrame(for: toController)
        
        var frame = fromView.frame
        frame.origin.y = frame.height
        fromView.frame = frame
        
        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeOut)
        {
            fromView.frame.origin.y = 0
        }
        
        return animator
    }
    
    override func interactionUpdate(with translation: CGPoint)
    {
        super.interactionUpdate(with: translation)
    }
    
    override func updateInteractiveTransition(_ percentComplete: CGFloat, with translation: CGPoint)
    {
        super.updateInteractiveTransition(percentComplete, with: translation)
    }
    
    override func restoreInteraction()
    {
        super.restoreInteraction()
    }
}
