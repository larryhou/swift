//
//  HandV9StraightFlush.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation


//同花顺
class HandV9StraightFlush:PokerHand
{
    var pattern:HandPattern { return HandPattern.StraightFlush }
    
    func getOccurrences() -> UInt
    {
        return
            4 * 10 *
            combinate(52 - 5, select: 2)
    }
    
    static func match(hand:HoldemHand) -> Bool
    {
//        var cards = hand.givenCards + hand.tableCards
        return false
    }
}