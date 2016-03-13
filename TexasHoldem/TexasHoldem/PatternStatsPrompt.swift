//
//  PatternStatsViewController.swift
//  TexasHoldem
//
//  Created by larryhou on 12/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation
import UIKit

class PatternStatsPrompt:UIAlertController
{
    var formatActionText:()->()
    {
        let font = UIFont(name: "Menlo", size: 18)
        
        var list:[UILabel] = []
        findObjectsInView(view, result: &list)
        
        return {
            for label in list
            {
                if let text = label.text where text.containsString(" - ")
                {
                    label.font = font
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        formatActionText();
    }
    
    func findObjectsInView<T where T:UIView>(view:UIView, inout result:[T])
    {
        for child in view.subviews
        {
            if child is T
            {
                result.append(child as! T)
            }
            else
            {
                findObjectsInView(child, result: &result)
            }
        }
    }
    
    func getDigitCount(value:Double) -> Int
    {
        var digitCount = 0
        
        var num = value
        while num >= 1
        {
            num /= 10
            digitCount += 1
        }
        
        return digitCount
    }
    
    func setPromptSheet(stats:[HandPattern:Int])
    {
        var total = 0
        for (_, count) in stats
        {
            total += count
        }
        
        let digitCount = getDigitCount(Double(total))
        
        let list = stats.sort({$0.0.rawValue > $1.0.rawValue})
        
        for (pattern, count) in list
        {
            let title = String(format: "%@ - %0\(digitCount)d/%d - %07.4f%%", pattern.description, count, total, 100 * Double(count) / Double(total))
            let action = UIAlertAction(title: title, style: .Default, handler: nil)
            addAction(action)
        }
        
        let action = UIAlertAction(title: "知道了", style: .Cancel, handler: nil)
        addAction(action)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        formatActionText()
    }
}
