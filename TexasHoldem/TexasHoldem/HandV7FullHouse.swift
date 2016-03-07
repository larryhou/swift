//
//  HandV7FullHouse.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 葫芦
class HandV7FullHouse:PokerHand
{
    var pattern:HandPattern { return HandPattern.FullHouse }
    
    func getOccurrences() -> UInt
    {
        
        return
            13 * combinate(4, select: 3) *
            12 * combinate(4, select: 2) *
            combinate(11, select: 2) * pow(4, exponent: 2) / permuate(3)
    }
    
    static func match(hand:HoldemHand) -> Bool
    {
        var cards = hand.givenCards + hand.tableCards
        
        var three = -1, two = -1
        var dict:[Int:[PokerCard]] = [:]
        for i in 0..<cards.count
        {
            let item = cards[i]
            if dict[item.value] == nil
            {
                dict[item.value] = []
            }
            
            dict[item.value]?.append(item)
        }
        
        for (value, list) in dict
        {
            if list.count == 3
            {
                if three == -1
                {
                    three = value
                }
                else // keep three of a kind with max value
                if let last = dict[three]?.first, item = list.first where item > last
                {
                    three = value
                }
            }
            
            if list.count >= 2 && value != three
            {
                if two == -1
                {
                    two = value
                }
                else // Keep two pair with max value
                if let last = dict[two]?.first, item = list.first where item > last
                {
                    two = value
                }
            }
        }
        
        if three != -1 && two != -1
        {
            hand.matches = dict[three]!
            for item in dict[two]!
            {
                if hand.matches.count < 5
                {
                    hand.matches.append(item)
                }
            }
            hand.pattern = HandPattern.FullHouse
            return true
        }
        
        return false
    }
}