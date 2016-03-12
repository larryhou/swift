//
//  HandV6Flush.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 同花
class HandV6Flush:PatternEvaluator
{
    static func getOccurrences() -> UInt
    {
        return
            combinate(13, select: 5) * 4 *
            13 * 3 / permuate(2)
    }
    
    static func evaluate(hand:PokerHand)
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        
        var flush:PokerColor!
        var dict:[PokerColor:[PokerCard]] = [:]
        for i in 0..<cards.count
        {
            let item = cards[i]
            if dict[item.color] == nil
            {
                dict[item.color] = []
            }
            
            dict[item.color]?.append(item)
            if let count = dict[item.color]?.count where count >= 5
            {
                flush = item.color
            }
        }
        
        hand.matches = Array(dict[flush]![0..<5])
    }
}