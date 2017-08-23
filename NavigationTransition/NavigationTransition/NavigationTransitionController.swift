//
//  TransitionController.swift
//  ViewOrientation
//
//  Created by larryhou on 16/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit

extension UIGestureRecognizerState
{
    var description:String
    {
        switch self
        {
            case .began:return "began"
            case .changed:return "changed"
            case .possible:return "possible"
            case .ended:return "ended"
            case .cancelled:return "cancelled"
            case .failed:return "failed"
        }
    }
}

class InteractiveNavigationController : UINavigationController
{
    var transitionController:NavigationTransitionController!
    
    override func loadView()
    {
        super.loadView()
        transitionController = NavigationTransitionController(navigationController: self, duration: 0.3)
    }
}

@objc protocol NavigationTransitionDelegate
{
    @objc optional func transitionShouldBegin(_ transitionController:NavigationTransitionController, gesture:UIPanGestureRecognizer)->Bool
    @objc optional func transitionStartUserInteraction(_ transitionController:NavigationTransitionController, transitionContext: UIViewControllerContextTransitioning, operation:UINavigationControllerOperation)->UIViewPropertyAnimator
}

@objc protocol TransitionControllerDelegate
{
    @objc optional func transitionUpdate(percentComplete percent:CGFloat)
}

class NavigationTransitionController : NSObject
{
    unowned var navigationController:UINavigationController
    var gesture:UIPanGestureRecognizer
    var duration:TimeInterval
    
    var transitionAnimator:UIViewPropertyAnimator!
    var transitionContext:UIViewControllerContextTransitioning!
    var operation:UINavigationControllerOperation = .none
    var anchor = CGPoint(x: 0.5, y: 0.5)
    
    var delegate:NavigationTransitionDelegate?
    
    init(navigationController controller:UINavigationController, duration:TimeInterval = 0.5)
    {
        self.navigationController = controller
        self.gesture = UIPanGestureRecognizer()
        self.duration = duration
        super.init()
        
        self.navigationController.delegate = self
        
        self.gesture.delegate = self
        self.gesture.maximumNumberOfTouches = 1
        self.gesture.addTarget(self, action: #selector(transitionUpdate(_:)))
        self.navigationController.view.addGestureRecognizer(self.gesture)
        
        if let popGesture = self.navigationController.interactivePopGestureRecognizer
        {
            self.gesture.require(toFail: popGesture)
        }
    }
    
    var initialized = false, interactive = false
    @objc func transitionUpdate(_ sender:UIPanGestureRecognizer)
    {
        if (sender.state == .began && !interactive)
        {
            initialized = true
            if let popController = navigationController.popViewController(animated: true)
            {
                let position = sender.location(in: popController.view)
                let frame = popController.view.frame
                anchor.x = position.x / frame.width
                anchor.y = position.y / frame.height
            }
        }
    }
}

extension NavigationTransitionController : UIGestureRecognizerDelegate
{
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if !interactive
        {
            let delegateAllowed:Bool
            if let allowed = delegate?.transitionShouldBegin?(self, gesture: gesture)
            {
                delegateAllowed = allowed
            }
            else
            {
                delegateAllowed = true
            }
            
            guard delegateAllowed else {return false}
            
            let translation = gesture.translation(in: gesture.view)
            let vertical = translation.y > 0 && abs(translation.y) > abs(translation.x)
            return vertical && navigationController.viewControllers.count >= 2
        }
        
        return transitionContext.isInteractive
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true
    }
}

//MARK: delegate
extension NavigationTransitionController : UINavigationControllerDelegate
{
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        self.operation = operation
        return self
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    {
        return self
    }
    
    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation
    {
        return .portrait
    }
    
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask
    {
        return .all
    }
}

//MARK: custom transition
extension NavigationTransitionController : UIViewControllerAnimatedTransitioning
{
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return self.duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        
    }
    
    func animationEnded(_ transitionCompleted: Bool)
    {
        gesture.removeTarget(self, action: #selector(interactionUpdate(_:)))
        transitionAnimator = nil
        transitionContext = nil
        initialized = false
        interactive = false
        print(#function)
    }
    
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating
    {
        return transitionAnimator
    }
}

//MARK: interaction
extension NavigationTransitionController : UIViewControllerInteractiveTransitioning
{
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning)
    {
        print(#function)
        
        interactive = true
        self.transitionContext = transitionContext
        self.gesture.addTarget(self, action: #selector(interactionUpdate(_:)))
        
        if let animator = delegate?.transitionStartUserInteraction?(self, transitionContext: transitionContext, operation: operation)
        {
            self.transitionAnimator = animator
        }
        else
        {
            self.transitionAnimator = startUserInteraction(transitionContext: transitionContext)
        }
        
        if !transitionContext.isInteractive
        {
            animate(to: .end)
        }
    }
    
    func startUserInteraction(transitionContext:UIViewControllerContextTransitioning)->UIViewPropertyAnimator
    {
        let _ = transitionContext.viewController(forKey: .from)!
        let toController = transitionContext.viewController(forKey: .to)!
        
        let fromView = transitionContext.view(forKey: .from)!
        let toView = transitionContext.view(forKey: .to)!
        
        toView.frame = transitionContext.finalFrame(for: toController)
        toView.clipsToBounds = true
        
        let transitionAnimator:UIViewPropertyAnimator
        if operation == .push
        {
            toView.backgroundColor = .clear
            toView.transform = CGAffineTransform.identity
            transitionContext.containerView.insertSubview(toView, aboveSubview: fromView)
            transitionAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear)
            {
                toView.backgroundColor = .white
            }
        }
        else
        {
            transitionContext.containerView.insertSubview(toView, belowSubview: fromView)
            transitionAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear)
            {
                fromView.backgroundColor = .clear
                fromView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
                fromView.layer.cornerRadius = 20
                fromView.alpha = 0.5
            }
        }
        
        transitionAnimator.addCompletion
        { position in
            if position == .end
            {
                transitionContext.finishInteractiveTransition()
            }
            else
            {
                transitionContext.cancelInteractiveTransition()
            }
            transitionContext.completeTransition(position == .end)
            print("complete", fromView.frame)
        }
        
        return transitionAnimator
    }
    
    func fraction(of translation:CGPoint)->CGFloat
    {
        return (operation == .push ? -1.0 : 1.0) * translation.y / transitionContext.containerView.bounds.midY * 2
    }
    
    func animate(to position:UIViewAnimatingPosition)
    {
        transitionAnimator.isReversed = position == .start
        if transitionAnimator.state == .inactive
        {
            transitionAnimator.startAnimation()
        }
        else
        {
            transitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 0.0)
        }
    }
    
    @objc func interactionUpdate(_ sender:UIPanGestureRecognizer)
    {
        switch sender.state
        {
            case .began, .changed:
                let translation = sender.translation(in: transitionContext.containerView)
                var fractionComplete = transitionAnimator.fractionComplete + fraction(of: translation)
                fractionComplete = min(1, max(0, fractionComplete))
                transitionAnimator.fractionComplete = fractionComplete
                transitionContext.updateInteractiveTransition(fractionComplete)
                sender.setTranslation(CGPoint.zero, in: transitionContext.containerView)
                updateControllers(with: translation, percentComplete: fractionComplete)
            case .ended, .cancelled, .failed:
                gesture.removeTarget(self, action: #selector(interactionUpdate(_:)))
                finishInteraction()
            default:break
        }
    }
    
    func updateControllers(with translation:CGPoint, percentComplete percent:CGFloat)
    {
        let fromController = transitionContext.viewController(forKey: .from)!
        if let delegate = fromController as? TransitionControllerDelegate
        {
            delegate.transitionUpdate?(percentComplete: percent)
        }
        
        let touchPoint = gesture.location(in: transitionContext.containerView)
        
        let fromView = fromController.view!
        var frame = fromView.frame
        frame.origin.x = touchPoint.x - frame.width  * anchor.x
        frame.origin.y = touchPoint.y - frame.height * anchor.y
        fromView.frame = frame
    }
    
    func finishInteraction()
    {
        guard transitionContext.isInteractive else {return}
        
        let position = completionAnimatingPosition()
        if position == .start
        {
            let view = transitionContext.view(forKey: .from)!
            let rect = transitionContext.containerView.frame
            let restoreAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .linear)
            {
                view.frame.origin.x += rect.midX - view.frame.midX
                view.frame.origin.y += rect.midY - view.frame.midY
            }
            gesture.isEnabled = false
            restoreAnimator.addCompletion
            { [unowned self] _ in
                self.gesture.isEnabled = true
                self.animate(to: position)
            }
            restoreAnimator.startAnimation()
        }
        else
        {
            animate(to: position)
        }
    }
    
    func completionAnimatingPosition()->UIViewAnimatingPosition
    {
        let velocity = gesture.velocity(in: transitionContext.containerView)
        let flicking = sqrt(velocity.x * velocity.x + velocity.y * velocity.y) > 1200
        let down = flicking && velocity.y > 0
        let up = flicking && velocity.y < 0
        
        let position:UIViewAnimatingPosition
        if (operation == .pop && down) || (operation == .push && up)
        {
            position = .end
        }
        else if (operation == .pop && up) || (operation == .push && down)
        {
            position = .start
        }
        else if transitionAnimator.fractionComplete >= 0.33
        {
            position = .end
        }
        else
        {
            position = .start
        }
        
        return position
    }
    
    var wantsInteractiveStart: Bool
    {
        return initialized
    }
}
