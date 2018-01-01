//
//  ViewController.swift
//  ForceTouch
//
//  Created by larryhou on 24/10/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import UIKit

class TouchAnchor:UIView
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect)
    {
        guard let context = UIGraphicsGetCurrentContext() else {return}
        context.saveGState()
        
        let thickness:CGFloat = 2
        
        color.setStroke()
        context.setLineWidth(thickness)
        
        let halo = CGMutablePath()
        halo.addEllipse(in: bounds.insetBy(dx: thickness / 2, dy: thickness / 2))
        context.addPath(halo)
        context.strokePath()
        
        color.setFill()
        
        let circle = CGMutablePath()
        circle.addEllipse(in: bounds.insetBy(dx: bounds.width / 4, dy: bounds.height / 4))
        context.addPath(circle)
        context.fillPath()
        
        context.restoreGState()
    }
    
    var color:UIColor = .green
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
}

class ViewController: UIViewController
{
    var pool:[TouchAnchor] = []
    var anchors:[UITouch:TouchAnchor] = [:]

    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.isMultipleTouchEnabled = true
        
        switch traitCollection.forceTouchCapability
        {
            case .available:print("forceTouch available")
            case .unavailable:print("forceTouch unavailable")
            case .unknown:print("forceTouch unknown")
        }
        
        if traitCollection.forceTouchCapability == .available
        {
            
        }
        else
        {
            
        }
    }
    
    var feedback:UISelectionFeedbackGenerator!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if feedback == nil
        {
            feedback = UISelectionFeedbackGenerator()
        }
        feedback.prepare()
        for touch in touches
        {
            let anchor:TouchAnchor
            if pool.count > 0
            {
                anchor = pool.remove(at: 0)
            }
            else
            {
                anchor = TouchAnchor()
            }
            
            anchor.isUserInteractionEnabled = false
            anchor.layer.removeAllAnimations()
            anchor.transform = CGAffineTransform.identity
            anchor.alpha = 1.0
            
            let diameter = touch.majorRadius * 2 * 2
            let center = touch.location(in: view)
            
            var frame = anchor.frame
            frame.origin = CGPoint(x: center.x - diameter / 2, y: center.y - diameter / 2)
            frame.size = CGSize(width: diameter, height: diameter)
            anchor.frame = frame
            anchor.setNeedsDisplay()
            
            view.addSubview(anchor)
            anchors[touch] = anchor
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch in touches
        {
            let center = touch.location(in: view)
            if let anchor = self.anchors[touch]
            {
                var frame = anchor.frame
                frame.origin = CGPoint(x: center.x - frame.width / 2, y: center.y - frame.height / 2)
                anchor.frame = frame
                
                let r:CGFloat, g:CGFloat
                let percent = touch.force / touch.maximumPossibleForce
                if percent > 0.5
                {
                    let ratio = (percent - 0.5) / 0.5
                    r = 1
                    g = 1 - ratio
                }
                else
                {
                    let ratio = percent / 0.5
                    r = ratio
                    g = 1
                }
                
                anchor.color = UIColor(red: r, green: g, blue: 0, alpha: 1)
            }
        }
        
//        feedback.selectionChanged()
//        feedback.prepare()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        UIView.animate(withDuration: 0.2, animations:
        { [unowned self] in
            for touch in touches
            {
                if let anchor = self.anchors[touch]
                {
                    anchor.alpha = 0
                    anchor.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                }
            }
        })
        { [unowned self] (done) in
            for touch in touches
            {
                if let anchor = self.anchors[touch]
                {
                    self.pool.append(anchor)
                    self.anchors.removeValue(forKey: touch)
                }
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.touchesEnded(touches, with: event)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
