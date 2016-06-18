//
//  HandV3TwoPair.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 两对
class HandV3TwoPair:PatternEvaluator
{
    static func getOccurrences() -> UInt
    {
        var count:UInt = 0
        
        count += // 2-2-1-1-1
            combinate(13, select: 2) * combinate(4, select: 2) *
            combinate(11, select: 3) * pow(4, exponent: 3)
        
        count += // 2-2-2-1
            combinate(13, select: 3) * combinate(4, select: 2) *
            (52 - 4 * 3)
        
        return count
    }
    
    static func evaluate(_ hand:PokerHand)
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        
        var dict:[Int:[PokerCard]] = [:]
        var group:[PokerCard] = []
        
        for i in 0..<cards.count
        {
            let item = cards[i]
            if dict[item.value] == nil
            {
                dict[item.value] = []
            }
            
            dict[item.value]?.append(item)
            if let count = dict[item.value]?.count where count == 2
            {
                group.append(item)
            }
        }
        
        let list = group.sorted(isOrderedBefore: {$0 > $1}).map({$0.value})
        
        var result:[PokerCard] = dict[list[0]]! + dict[list[1]]!
        for i in 0..<cards.count
        {
            if list.index(of: cards[i].value) < 0 && result.count < 5
            {
                result.append(cards[i])
            }
        }
        
        hand.matches = result;
    }
}
