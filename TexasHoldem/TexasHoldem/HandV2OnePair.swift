//
//  HandV2OnePair.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 一对
class HandV2OnePair : PokerHand
{
    var pattern:HandPattern { return HandPattern.OnePair }
    
    func getOccurrences() -> UInt
    {
        return
            13 * combinate(4, select: 2) *
            permutate(12, select: 5) * pow(4, exponent: 5) / permuate(5)
    }
    
    static func match(hand:HoldemHand) -> Bool
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        
        var pair = -1
        var dict:[Int:[PokerCard]] = [:]
        
        for i in 0..<cards.count
        {
            let item = cards[i]
            if dict[item.value] == nil
            {
                dict[item.value] = []
            }
            
            dict[item.value]?.append(item)
            if let list = dict[item.value] where list.count == 2
            {
                pair = item.value
            }
        }
        
        if dict.count == 6 && pair != -1
        {
            var result:[PokerCard] = dict[pair]!
            for i in 0..<cards.count
            {
                if cards[i].value != pair && result.count < 5
                {
                    result.append(cards[i])
                }
            }
            
            hand.matches = result
            hand.pattern = HandPattern.OnePair
            return true
        }
        
        return false
    }
    
}