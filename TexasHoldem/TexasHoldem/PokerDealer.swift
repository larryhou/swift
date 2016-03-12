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
    private static let packOfCards:[PokerCard] =
    {
        var result:[PokerCard] = []
        let colors:[PokerColor] = [.Spade, .Club, .Heart, .Diamond]
        for n in 1...13
        {
            for i in 0..<colors.count
            {
                let card = PokerCard(color: colors[i], value: n)
                result.append(card)
            }
        }
        
        return result
    }()
    
    private static var handRecycle:[PokerHand] = []
    
    static func deal(num:Int) -> [PokerHand]
    {
        let personCount = min((52 - 5) / 2, num);
        
        var cards_pool = packOfCards
        var hands_pool = handRecycle
        
        var dict:[Int:[PokerCard]] = [:]
        for r in 1...2
        {
            for i in 1...personCount
            {
                if r == 1
                {
                    dict[i] = []
                }
                
                let index = arc4random_uniform(UInt32(cards_pool.count))
                let card = cards_pool.removeAtIndex(Int(index))
                dict[i]?.append(card)
            }
        }
        
        var tableCards:[PokerCard] = []
        for _ in 1...5
        {
            let index = arc4random_uniform(UInt32(cards_pool.count))
            let card = cards_pool.removeAtIndex(Int(index))
            tableCards.append(card)
        }
        
        var result:[PokerHand] = []
        for i in 1...num
        {
            if let givenCards = dict[i]
            {
                let hand:PokerHand
                if hands_pool.count > 0
                {
                    hand = hands_pool.removeFirst()
                    hand.givenCards = givenCards
                    hand.tableCards = tableCards
                }
                else
                {
                    hand = PokerHand(givenCards: givenCards, tableCards: tableCards)
                    handRecycle.append(hand)
                }
                
                result.append(hand)
            }
        }
        
        return result
    }
}