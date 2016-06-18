//
//  HandV9StraightFlush.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation


//同花顺
class HandV9StraightFlush:PatternEvaluator
{
    static func getOccurrences() -> UInt
    {
        return
            4 * 10 *
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
        
        for i in 0..<stack.count - 5
        {
            var result = [stack[i]]
            for j in i + 1..<i + 5
            {
                if stack[j - 1].color != stack[j].color
                {
                    break
                }
                result.append(stack[j])
            }
            
            if result.count == 5
            {
                hand.matches = result
            }
        }
    }
}
