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
    case highCard = 1, onePair, twoPair, threeOfKind, straight, flush, fullHouse, fourOfKind, straightFlush
    
    var description:String
    {
        switch self
        {
            case .highCard:     return "高牌"
            case .onePair:      return "一对"
            case .twoPair:      return "两对"
            case .threeOfKind:  return "三张" //绿色
            case .straight:     return "顺子" //蓝色
            case .flush:        return "同花" //紫色
            case .fullHouse:    return "葫芦" //橙色
            case .fourOfKind:   return "炸弹" //红色
            case .straightFlush:return "花顺" //
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
            
            colorStats[item.color]! += 1
            maxSameColorCount = max(colorStats[item.color]!, maxSameColorCount)
        }
        
        var kindStats:[Int:Int] = [:]
        for (_, list) in dict
        {
            if kindStats[list.count] == nil
            {
                kindStats[list.count] = 0
            }
            
            kindStats[list.count]! += 1
        }
        
        if let v4 = kindStats[4] where v4 >= 1
        {
            return .fourOfKind
        }
        
        if let v3 = kindStats[3], v2 = kindStats[2] where (v3 == 1 && v2 >= 1) || (v3 >= 2)
        {
            return .fullHouse
        }
        
        if cards[0].value == 1
        {
            cards.append(cards[0])
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
                    
                    count += 1
                }
                
                if count == 5
                {
                    return .straightFlush
                }
            }
            
            return .straight
        }
        
        if maxSameColorCount >= 5
        {
            return .flush
        }
        
        if let v3 = kindStats[3] where v3 == 1
        {
            return .threeOfKind
        }
        
        if let v2 = kindStats[2]
        {
            if v2 >= 2
            {
                return .twoPair
            }
            else
            if v2 == 1
            {
                return .onePair
            }
        }
        
        return .highCard
    }
    
    func evaluate()
    {
        pattern = recognize()
        switch pattern!
        {
            case .highCard:HandV1HighCard.evaluate(self)
            case .onePair:HandV2OnePair.evaluate(self)
            case .twoPair:HandV3TwoPair.evaluate(self)
            case .threeOfKind:HandV4TreeOfKind.evaluate(self)
            case .straight:HandV5Straight.evaluate(self)
            case .flush:HandV6Flush.evaluate(self)
            case .fullHouse:HandV7FullHouse.evaluate(self)
            case .fourOfKind:HandV8FourOfKind.evaluate(self)
            case .straightFlush:HandV9StraightFlush.evaluate(self)
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
