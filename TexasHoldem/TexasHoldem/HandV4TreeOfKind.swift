//
//  HandV4TreeOfKind.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 三张
class HandV4TreeOfKind:PokerHand
{
    var pattern:HandPattern { return HandPattern.TreeOfKind }
    
    func getOccurrences() -> UInt
    {
        return
            13 * combinate(4, select: 3) *
            combinate(12, select: 4) * pow(4, exponent: 4)
    }
    
    static func match(hand:HoldemHand) -> Bool
    {
//        var cards = hand.givenCards + hand.tableCards
        return false
    }
}