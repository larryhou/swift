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
    
//    func match(cards:[PokerCard])->Bool
//    {
//        return self.dynamicType.match(cards)
//    }
}

class PokerCard
{
    private let hash = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
    
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
        return hash[value - 1] + color.description
    }
}

extension _ArrayType where Generator.Element == PokerCard
{
    func sort()->[PokerCard]
    {
        return sort({$0.value > $1.value})
    }
    
    func sortWithColor()->[PokerCard]
    {
        return sort({ $0.value != $1.value ? $0.value > $1.value : $0.color.rawValue < $1.color.rawValue })
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
}