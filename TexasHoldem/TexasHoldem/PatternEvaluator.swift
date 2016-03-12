//
//  PatternRecognizer.swift
//  TexasHoldem
//
//  Created by larryhou on 12/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

protocol PatternEvaluator
{
    static func evaluate(hand:PokerHand);
    static func getOccurrences() -> UInt;
}