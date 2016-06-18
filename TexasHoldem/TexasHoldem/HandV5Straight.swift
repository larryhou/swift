//
//  HandV5Straight.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 顺子
class HandV5Straight:PatternEvaluator
{
    static func getOccurrences() -> UInt
    {
        return
            10 * pow(4, exponent: 5) *
            combinate(52 - 5, select: 2)
    }
    
    static func evaluate(_ hand:PokerHand)
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        if cards[0].value == 1
        {
            cards.append(cards[0])
        }
        
        var stack = [cards[0]]
        for i in 0..<cards.count - 1
        {
            if (cards[i].value - cards[i + 1].value == 1) || (cards[i].value == 1/*A*/ && cards[i + 1].value == 13/*K*/)
            {
                stack.append(cards[i + 1])
            }
            else
            if stack.count < 5
            {
                stack = [cards[i + 1]]
            }
        }
        
        hand.matches = Array(stack[0..<5])
    }
}
