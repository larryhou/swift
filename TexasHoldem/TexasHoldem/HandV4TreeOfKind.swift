//
//  HandV4TreeOfKind.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 三张
class HandV4TreeOfKind:PokerHand
{
    var pattern:HandPattern { return HandPattern.TreeOfKind }
    
    func getOccurrences() -> UInt
    {
        return
            13 * combinate(4, select: 3) *
            combinate(12, select: 4) * pow(4, exponent: 4)
    }
    
    static func match(hand:HoldemHand) -> Bool
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        
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
        
        var three = -1
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
                    three = value
                }
            }
        }
        
        if three != -1
        {
            hand.matches = dict[three]
            hand.pattern = HandPattern.TreeOfKind
            return true
        }
        
        return false
    }
}