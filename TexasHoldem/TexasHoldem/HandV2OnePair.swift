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
//        var cards = hand.givenCards + hand.tableCards
        return false
    }
    
}