//
//  HandV8FourOfKind.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 炸弹
class HandV8FourOfKind:PatternEvaluator
{
    static func getOccurrences() -> UInt
    {
        return 13 * combinate(52 - 4, select: 3)
    }
    
    static func evaluate(_ hand:PokerHand)
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        
        var four = -1
        var dict:[Int:[PokerCard]] = [:]
        for i in 0..<cards.count
        {
            let item = cards[i]
            if dict[item.value] == nil
            {
                dict[item.value] = []
            }
            
            dict[item.value]?.append(item)
            if let count = dict[item.value]?.count where count == 4
            {
                four = item.value
            }
        }
        
        var result = dict[four]!
        for i in 0..<cards.count
        {
            if cards[i].value != four
            {
                result.append(cards[i])
                break
            }
        }
        
        hand.matches = result
    }
}
