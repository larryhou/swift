//
//  HandV2OnePair.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 一对
class HandV2OnePair : PatternEvaluator
{
    static func getOccurrences() -> UInt
    {
        return
            13 * combinate(4, select: 2) *
            combinate(12, select: 5) * pow(4, exponent: 5)
    }
    
    static func evaluate(hand: PokerHand)
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        var dict:[Int:[PokerCard]] = [:]
        
        var pair = -1
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
                pair = item.value
            }
        }
        
        var result:[PokerCard] = dict[pair]!
        for i in 0..<cards.count
        {
            if cards[i].value != pair && result.count < 5
            {
                result.append(cards[i])
            }
        }
        
        hand.matches = result
    }
}