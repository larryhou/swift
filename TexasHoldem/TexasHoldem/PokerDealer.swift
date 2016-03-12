//
//  TexasHoldemDealer.swift
//  TexasHoldem
//
//  Created by larryhou on 12/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

class PokerDealer
{
    static func deal(var num:Int) -> [PokerHand]
    {
        num = min((52 - 5) / 2, num);
        
        var pool:[PokerCard] = []
        let colors:[PokerColor] = [.Spade, .Club, .Heart, .Diamond]
        for n in 1...13
        {
            for i in 0..<colors.count
            {
                let card = PokerCard(color: colors[i], value: n)
                pool.append(card)
            }
        }
        
        var dict:[Int:[PokerCard]] = [:]
        for r in 1...2
        {
            for i in 1...num
            {
                if r == 1
                {
                    dict[i] = []
                }
                
                let index = arc4random_uniform(UInt32(pool.count))
                let card = pool.removeAtIndex(Int(index))
                dict[i]?.append(card)
            }
        }
        
        var tableCards:[PokerCard] = []
        for _ in 1...5
        {
            let index = arc4random_uniform(UInt32(pool.count))
            let card = pool.removeAtIndex(Int(index))
            tableCards.append(card)
        }
        
        var result:[PokerHand] = []
        for i in 1...num
        {
            if let givenCards = dict[i]
            {
                let hand = PokerHand(givenCards: givenCards, tableCards: tableCards)
                result.append(hand)
            }
        }
        
        return result
    }
}