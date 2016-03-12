//
//  PokerHand.swift
//  TexasHoldem
//
//  Created by larryhou on 9/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

enum HandPattern:UInt8
{
    case HighCard = 1, OnePair, TwoPair, ThreeOfKind, Straight, Flush, FullHouse, FourOfKind, StraightFlush
    
    var description:String
    {
        switch self
        {
            case .HighCard:     return "高牌"
            case .OnePair:      return "一对"
            case .TwoPair:      return "两对"
            case .ThreeOfKind:  return "三张"
            case .Straight:     return "顺子"
            case .Flush:        return "同花"
            case .FullHouse:    return "葫芦"
            case .FourOfKind:   return "炸弹"
            case .StraightFlush:return "花顺"
        }
    }
}

class PokerHand
{
    var givenCards:[PokerCard]
    var tableCards:[PokerCard]
    
    var pattern:HandPattern!
    var matches:[PokerCard]!
    
    private var _isReady:Bool = false
    var isReady:Bool { return _isReady }
    
    init()
    {
        self.givenCards = []
        self.tableCards = []
    }
    
    init(givenCards:[PokerCard], tableCards:[PokerCard])
    {
        self.givenCards = givenCards
        self.tableCards = tableCards
    }
    
    func reset()
    {
        self.givenCards = []
        self.tableCards = []
        self.matches = nil
        self.pattern = nil
    }
    
    func checkQualified()
    {
        assert(givenCards.count == 2)
        assert(tableCards.count == 5)
    }
    
    func recognize() -> HandPattern
    {
        var cards = (givenCards + tableCards).sort()
        
        var colorStats:[PokerColor:Int] = [:]
        var maxSameColorCount = 0
        
        var dict:[Int:[PokerCard]] = [:]
        for i in 0..<cards.count
        {
            let item = cards[i]
            if dict[item.value] == nil
            {
                dict[item.value] = []
            }
            
            dict[item.value]?.append(item)
            
            if colorStats[item.color] == nil
            {
                colorStats[item.color] = 0
            }
            
            colorStats[item.color]!++
            maxSameColorCount = max(colorStats[item.color]!, maxSameColorCount)
        }
        
        var kindStats:[Int:Int] = [:]
        for (_, list) in dict
        {
            if kindStats[list.count] == nil
            {
                kindStats[list.count] = 0
            }
            
            kindStats[list.count]!++
        }
        
        if let v4 = kindStats[4] where v4 >= 1
        {
            return .FourOfKind
        }
        
        if let v3 = kindStats[3], v2 = kindStats[2] where (v3 == 1 && v2 >= 1) || (v3 >= 2)
        {
            return .FullHouse
        }
        
        var stack = [cards[0]]
        for i in 1..<cards.count
        {
            if (cards[i - 1].value - cards[i].value == 1) || (cards[i - 1].value == 1/*A*/ && cards[i].value == 13/*K*/)
            {
                stack.append(cards[i])
            }
            else
            if stack.count < 5
            {
                stack = [cards[i]]
            }
        }
        
        if stack.count >= 5
        {
            for i in 0..<stack.count - 5
            {
                var count = 1
                for j in i + 1..<i + 5
                {
                    if stack[j - 1].color != stack[j].color
                    {
                        break
                    }
                    
                    count++
                }
                
                if count == 5
                {
                    return .StraightFlush
                }
            }
            
            return .Straight
        }
        
        if maxSameColorCount >= 5
        {
            return .Flush
        }
        
        if let v3 = kindStats[3] where v3 == 1
        {
            return .ThreeOfKind
        }
        
        if let v2 = kindStats[2]
        {
            if v2 >= 2
            {
                return .TwoPair
            }
            else
            if v2 == 1
            {
                return .OnePair
            }
        }
        
        return .HighCard
    }
    
    func evaluate()
    {
        pattern = recognize()
        switch pattern!
        {
            case .HighCard:HandV1HighCard.evaluate(self)
            case .OnePair:HandV2OnePair.evaluate(self)
            case .TwoPair:HandV3TwoPair.evaluate(self)
            case .ThreeOfKind:HandV4TreeOfKind.evaluate(self)
            case .Straight:HandV5Straight.evaluate(self)
            case .Flush:HandV6Flush.evaluate(self)
            case .FullHouse:HandV7FullHouse.evaluate(self)
            case .FourOfKind:HandV8FourOfKind.evaluate(self)
            case .StraightFlush:HandV9StraightFlush.evaluate(self)
        }
        
        _isReady = true
    }
    
    var description:String
    {
        return String(format: "%@ {%@} [%@] [%@]", pattern.description, matches.toString(), givenCards.toString(), tableCards.toString())
    }
}

func == (left:PokerHand, right:PokerHand) -> Bool
{
    for i in 0..<5
    {
        if left.matches[i] != right.matches[i]
        {
            return false
        }
    }
    
    return true
}

func != (left:PokerHand, right:PokerHand) -> Bool
{
    return !(left == right)
}

func > (left:PokerHand, right:PokerHand) -> Bool
{
    for i in 0..<5
    {
        if left.matches[i] != right.matches[i]
        {
            return left.matches[i] > right.matches[i]
        }
    }
    
    return false
}

func >= (left:PokerHand, right:PokerHand) -> Bool
{
    for i in 0..<5
    {
        if left.matches[i] != right.matches[i]
        {
            return left.matches[i] > right.matches[i]
        }
    }
    
    return true
}

func < (left:PokerHand, right:PokerHand) -> Bool
{
    for i in 0..<5
    {
        if left.matches[i] != right.matches[i]
        {
            return left.matches[i] < right.matches[i]
        }
    }
    
    return false
}

func <= (left:PokerHand, right:PokerHand) -> Bool
{
    for i in 0..<5
    {
        if left.matches[i] != right.matches[i]
        {
            return left.matches[i] < right.matches[i]
        }
    }
    
    return true
}
