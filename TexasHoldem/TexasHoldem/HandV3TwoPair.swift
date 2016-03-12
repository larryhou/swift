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
        return
            13 * combinate(4, select: 2) *
            12 * combinate(4, select: 2) / permuate(2) *
            permutate(11, select: 3) * pow(4, exponent: 3) /  permuate(3)
    }
    
    static func evaluate(hand:PokerHand)
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        
        var dict:[Int:[PokerCard]] = [:]
        var list:[Int] = []
        
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
                list.append(item.value)
            }
        }
        
        list.sortInPlace({$0 > $1})
        
        var result:[PokerCard] = dict[list[0]]! + dict[list[1]]!
        for i in 0..<cards.count
        {
            if list.indexOf(cards[i].value) < 0 && result.count < 5
            {
                result.append(cards[i])
            }
        }
        
        hand.matches = result;
    }
}