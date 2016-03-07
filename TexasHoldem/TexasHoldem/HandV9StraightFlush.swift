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
        var cards = (hand.givenCards + hand.tableCards).sort()
        
        var source = [cards[0]]
        for i in 0..<cards.count - 1
        {
            if (cards[i].value - cards[i + 1].value == 1) || (cards[i].value == 1/*A*/ && cards[i + 1].value == 13/*K*/)
            {
                source.append(cards[i + 1])
            }
            else
            if source.count < 5
            {
                source = [cards[i]]
            }
        }
        
        if source.count >= 5
        {
            for i in 0..<source.count - 5
            {
                var result = [source[i]]
                for j in i + 1..<i + 5
                {
                    if source[j - 1].color != source[j].color
                    {
                        break
                    }
                    result.append(source[j])
                }
                
                if result.count == 5
                {
                    hand.matches = result
                    hand.pattern = HandPattern.StraightFlush
                    return true
                }
            }
        }
        
        return false
    }
}