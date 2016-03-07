//
//  HandV3TwoPair.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 两对
class HandV3TwoPair:PokerHand
{
    var pattern:HandPattern { return HandPattern.TwoPair }
    
    func getOccurrences() -> UInt
    {
        return
            13 * combinate(4, select: 2) *
            12 * combinate(4, select: 2) / permuate(2) *
            permutate(11, select: 3) * pow(4, exponent: 3) /  permuate(3)
    }
    
    static func match(hand:HoldemHand) -> Bool
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        
        var dict:[Int:[PokerCard]] = [:]
        var sets:[Int] = []
        
        for i in 0..<cards.count
        {
            let item = cards[i]
            if dict[item.value] == nil
            {
                dict[item.value] = []
                sets.append(item.value)
            }
            
            dict[item.value]?.append(item)
        }
        
        var result:[PokerCard] = []
        var tail:PokerCard!
        
        for value in sets
        {
            if let list = dict[value]
            {
                if list.count == 2 && result.count < 4
                {
                    result += list
                }
                else
                if tail == nil
                {
                    tail = list[0]
                }
            }
        }
        
        if result.count == 4
        {
            result.append(tail)
            
            hand.matches = result
            hand.pattern = HandPattern.TwoPair
            return true
        }
        
        return false
    }
}