//
//  HandV1HighCard.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 高牌
class HandV1HighCard: PatternEvaluator {
    static func getOccurrences() -> UInt {
        return combinate(13, select: 7) * pow(4, exponent: 7)
    }

    static func evaluate(_ hand: PokerHand) {
        var cards = (hand.givenCards + hand.tableCards).sort()
        hand.matches = Array(cards[0..<5])
    }
}
