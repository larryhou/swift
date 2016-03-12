//
//  GameRound.swift
//  TexasHoldem
//
//  Created by larryhou on 12/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

extension PokerCard
{
    var rawValue:UInt8
    {
        return UInt8(color.rawValue << 4) | UInt8(value)
    }
    
    static func parse(rawValue:UInt8) -> PokerCard
    {
        let value = Int(rawValue & 0xF)
        let color = PokerColor(rawValue: rawValue >> 4 & 0xF)!
        return PokerCard(color: color, value: value)
    }
    
    static func parse(rawValue:UInt8, card:PokerCard)
    {
        card.value = Int(rawValue & 0xF)
        card.color = PokerColor(rawValue: rawValue >> 4 & 0xF)!
    }
}

extension PokerHand
{
    var rawValue:(UInt8, [UInt8], [UInt8])
    {
        return (pattern.rawValue, givenCards.map({$0.rawValue}), tableCards.map({$0.rawValue}))
    }
    
    static func parse(rawValue:(UInt8, [UInt8], [UInt8])) -> PokerHand
    {
        let givenCards = rawValue.1.map({PokerCard.parse($0)})
        let tableCards = rawValue.2.map({PokerCard.parse($0)})
        let hand = PokerHand(givenCards: givenCards, tableCards: tableCards)
        hand.pattern = HandPattern(rawValue: rawValue.0)!
        return hand
    }
    
    static func parse(rawValue:(UInt8, [UInt8], [UInt8]), hand:PokerHand)
    {
        hand.reset()
        hand.givenCards = rawValue.1.map({PokerCard.parse($0)})
        hand.tableCards = rawValue.2.map({PokerCard.parse($0)})
        hand.pattern = HandPattern(rawValue: rawValue.0)!
    }
}

class RawPokerHand
{
    let id:UInt8
    let data:(UInt8, [UInt8], [UInt8])
    
    init(id:UInt8, data:(UInt8, [UInt8], [UInt8]))
    {
        self.id = id
        self.data = data
    }
}

class UniqueRound
{
    var index:Int
    var list:[RawPokerHand]
    
    init(index:Int)
    {
        self.index = index
        self.list = []
    }
}