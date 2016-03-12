//
//  HandV7FullHouse.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 葫芦
class HandV7FullHouse:PatternEvaluator
{
    static func getOccurrences() -> UInt
    {
        
        return
            13 * combinate(4, select: 3) *
            12 * combinate(4, select: 2) *
            combinate(11, select: 2) * pow(4, exponent: 2) / permuate(3)
    }
    
    static func evaluate(hand:PokerHand)
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        
        var three = -1, prev3 = -1, two = -1
        var dict:[Int:[PokerCard]] = [:]
        for i in 0..<cards.count
        {
            let item = cards[i]
            if dict[item.value] == nil
            {
                dict[item.value] = []
            }
            
            dict[item.value]?.append(item)
        }
        
        for (value, list) in dict
        {
            if list.count == 3
            {
                if three == -1
                {
                    three = value
                }
                else // Keep three of a kind with max value
                if let last = dict[three]?.first, item = list.first where item > last
                {
                    prev3 = three
                    three = value
                }
            }
            
            if list.count == 2
            {
                if two == -1
                {
                    two = value
                }
                else // Keep two pair with max value
                if let last = dict[two]?.first, item = list.first where item > last
                {
                    two = value
                }
            }
        }
        
        if prev3 != -1 && prev3 > two
        {
            two = prev3
        }
        
        hand.matches = dict[three]! + Array(dict[two]![0..<2])
    }
}