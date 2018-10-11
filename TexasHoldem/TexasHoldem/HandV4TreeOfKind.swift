//
//  HandV4TreeOfKind.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

// 三张
class HandV4TreeOfKind: PatternEvaluator {
    static func getOccurrences() -> UInt {
        return
            13 * combinate(4, select: 3) *
            combinate(12, select: 4) * pow(4, exponent: 4)
    }

    static func evaluate(_ hand: PokerHand) {
        var cards = (hand.givenCards + hand.tableCards).sort()
        var dict: [Int: [PokerCard]] = [:]

        var three = -1
        for i in 0..<cards.count {
            let item = cards[i]
            if dict[item.value] == nil {
                dict[item.value] = []
            }

            dict[item.value]?.append(item)
            if let count = dict[item.value]?.count where count == 3 {
                three = item.value
            }
        }

        var result: [PokerCard] = dict[three]!

        for i in 0..<cards.count {
            if cards[i].value != three && result.count < 5 {
                result.append(cards[i])
            }
        }

        hand.matches = result
    }
}
