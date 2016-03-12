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
}
