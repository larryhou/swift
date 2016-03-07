//
//  HandV1HighCard.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 高牌
class HandV1HighCard : PokerHand
{
    var pattern:HandPattern { return HandPattern.HighCard }
    
    func getOccurrences() -> UInt
    {
        return permutate(13, select: 7) * pow(4, exponent: 7) / permuate(7)
    }
    
    static func match(hand:HoldemHand) -> Bool
    {
        var cards = (hand.givenCards + hand.tableCards).sort()
        
        var result:[PokerCard] = []
        for i in 1..<cards.count
        {
            if cards[i].value == cards[i - 1].value
            {
                return false
            }
            
            result.append(cards[i])
        }
        
        hand.matches = result
        hand.pattern = HandPattern.HighCard
        return true
    }
}