//
//  HandV6Flush.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 同花
class HandV6Flush:PokerHand
{
    var pattern:HandPattern { return HandPattern.Flush }

    func getOccurrences() -> UInt
    {
        return
            combinate(13, select: 5) * 4 *
            13 * 3 / permuate(2)
    }
    
    static func match(hand:HoldemHand) -> Bool
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        
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
                hand.matches = dict[item.color]
                hand.pattern = HandPattern.Flush
                return true
            }
        }
        
        return false
    }
}