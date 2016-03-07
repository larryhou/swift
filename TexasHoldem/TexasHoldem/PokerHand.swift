//
//  PokerHand.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

enum HandPattern:Int
{
    case HighCard = 1, OnePair, TwoPair, TreeOfKind, Straight, Flush, FullHouse, FourOfKind, StraightFlush
    
    var description:String
    {
        switch self
        {
            case .HighCard:return "高牌"
            case .OnePair:return "一对"
            case .TwoPair:return "两对"
            case .TreeOfKind:return "三张"
            case .Straight:return "顺子"
            case .Flush:return "同花"
            case .FullHouse:return "葫芦"
            case .FourOfKind:return "炸弹"
            case .StraightFlush:return "花顺"
        }
    }
}

enum PokerColor:Int
{
    case Spade = 1, Club, Heart, Diamond
    
    var description:String
    {
        switch (self)
        {
            case .Spade     :return "♠︎"
            case .Club      :return "♣︎"
            case .Heart     :return "♥︎"
            case .Diamond   :return "♦︎"
        }
    }
}

protocol PokerHand
{
    var pattern:HandPattern {get}
    
    func getOccurrences()->UInt
    static func match(hand:HoldemHand)->Bool
}

extension PokerHand
{
    var posibility:Double
    {
        return self.getOccurrences().double / combinate(52, select: 7).double
    }
    
    func toString()->String
    {
        return String(format: "%20s %8d %5.8f%%",
            COpaquePointer(String(self.dynamicType).cStringUsingEncoding(NSUTF8StringEncoding)!),
            getOccurrences(),
            self.posibility * 100)
    }
}

class PokerCard
{
    static let hash = [" A", " 2", " 3", " 4", " 5", " 6", " 7", " 8", " 9", "10", " J", " Q", " K"]
    
    let color:PokerColor
    let value:Int
    
    var id:String { return String(format: "%02d_%d", value, color.rawValue) }
    
    init(color:PokerColor, value:Int)
    {
        self.color = color
        self.value = value
    }
    
    var description:String
    {
        return PokerCard.hash[value - 1] + color.description
    }
}

extension _ArrayType where Generator.Element == PokerCard
{
    func sort()->[PokerCard]
    {
        return sort({$0 > $1})
    }
    
    func sortWithColor()->[PokerCard]
    {
        return sort({ $0 != $1 ? $0 > $1 : $0.color.rawValue < $1.color.rawValue })
    }
    
    func toString() -> String
    {
        return map({$0.description}).joinWithSeparator(" ")
    }
}

func == (left:PokerCard, right:PokerCard)->Bool
{
    return left.value == right.value
}

func != (left:PokerCard, right:PokerCard)->Bool
{
    return left.value != right.value
}

func > (left:PokerCard, right:PokerCard)->Bool
{
    return (left.value > right.value && right.value != 1) || (left.value < right.value && left.value == 1)
}

func < (left:PokerCard, right:PokerCard)->Bool
{
    return right > left
}

func >= (left:PokerCard, right:PokerCard)->Bool
{
    return left == right || left > right
}

func <= (left:PokerCard, right:PokerCard)->Bool
{
    return right >= left
}

class HoldemHand
{
    let givenCards:[PokerCard]
    let tableCards:[PokerCard]
    
    var pattern:HandPattern!
    var matches:[PokerCard]!
    
    init(givenCards:[PokerCard], tableCards:[PokerCard])
    {
        self.givenCards = givenCards
        self.tableCards = tableCards
    }
    
    func check()
    {
        assert(givenCards.count == 2)
        assert(tableCards.count == 5)
    }
    
    func evaluate()
    {
        if HandV8FourOfKind.match(self)
        {
            return
        }
        
        if HandV7FullHouse.match(self)
        {
            return
        }
        
        if HandV9StraightFlush.match(self)
        {
            return
        }
        
        if HandV6Flush.match(self)
        {
            return
        }
        
        if HandV5Straight.match(self)
        {
            return
        }
        
        if HandV4TreeOfKind.match(self)
        {
            return
        }
        
        if HandV3TwoPair.match(self)
        {
            return
        }
        
        if HandV2OnePair.match(self)
        {
            return
        }
        
        HandV1HighCard.match(self)
    }
    
    var description:String
    {
        return String(format: "%@ {%@} [%@] - [%@]", pattern.description, matches.toString(), givenCards.toString(), tableCards.toString())
    }
}

class PokerDealer
{
    static func deal(num:Int) -> [HoldemHand]
    {
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
        
        var result:[HoldemHand] = []
        for i in 1...num
        {
            if let givenCards = dict[i]
            {
                let hand = HoldemHand(givenCards: givenCards, tableCards: tableCards)
                result.append(hand)
            }
        }
        
        return result
    }
}