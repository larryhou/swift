//
//  PatternRecognizer.swift
//  TexasHoldem
//
//  Created by larryhou on 12/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

protocol PatternEvaluator {
    static func evaluate(_ hand: PokerHand)
    static func getOccurrences() -> UInt
}

extension Int {
    var double: Double {
        return Double(self)
    }
}

extension PatternEvaluator {
    static var probability: Double {
        return getOccurrences().double / combinate(52, select: 7).double
    }

    static var description: String {
        return String(format: "%@ %7.4f%%", String(self), probability * 100)
    }
}
