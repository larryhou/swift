//
//  HandV8FourOfKind.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 炸弹
class HandV8FourOfKind:PokerHand
{
    var pattern:HandPattern { return HandPattern.FourOfKind }
    
    func getOccurrences() -> UInt
    {
        return 13 * (52 - 4) /  permuate(2)
    }
    
    static func match(hand:HoldemHand) -> Bool
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        
        var dict:[Int:[PokerCard]] = [:]
        for i in 0..<cards.count
        {
            let item = cards[i]
            if dict[item.value] == nil
            {
                dict[item.value] = []
            }
            
            dict[item.value]?.append(item)
            if let count = dict[item.value]?.count where count == 4
            {
                hand.matches = dict[item.value]
                for j in 0..<cards.count
                {
                    if cards[j].value != item.value
                    {
                        hand.matches.append(cards[j])
                        break
                    }
                }
                hand.pattern = HandPattern.FourOfKind
                return true
            }
        }
        
        return false
    }
}