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
//        var cards = hand.givenCards + hand.tableCards
        return false
    }
}