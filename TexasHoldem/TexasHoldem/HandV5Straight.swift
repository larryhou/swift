//
//  HandV5Straight.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 顺子
class HandV5Straight:PokerHand
{
    var pattern:HandPattern { return HandPattern.Straight }
    
    func getOccurrences() -> UInt
    {
        return
            10 * pow(4, exponent: 5) *
            combinate(52 - 5, select: 2)
    }
    
    static func match(hand:HoldemHand) -> Bool
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        
        var num = 0, offset = 0
        for i in 0..<cards.count - 1
        {
            if cards[i].value - cards[i + 1].value == 1
            {
                num++
            }
            else
            {
                offset = i
                num = 0
            }
        }
        
        if num >= 5 || (num == 4 && cards.last!.value == 13/*K*/ && cards[0].value == 1/*A*/)
        {
            hand.matches = []
            for j in offset..<min(cards.count, offset + 5)
            {
                hand.matches.append(cards[j])
            }
            
            if hand.matches.count == 4
            {
                hand.matches.append(cards[0])
            }
            
            hand.pattern = HandPattern.Straight
            return true
        }
        
        return false
    }
}