//
//  PokerCard.swift
//  TexasHoldem
//
//  Created by larryhou on 9/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

enum PokerColor:UInt8
{
    case spade = 4, club = 3, heart = 2, diamond = 1
    
    var description:String
    {
        switch (self)
        {
            case .spade     :return "♠︎"
            case .club      :return "♣︎"
            case .heart     :return "♥︎"
            case .diamond   :return "♦︎"
        }
    }
}

class PokerCard
{
    private static let hash = [" A", " 2", " 3", " 4", " 5", " 6", " 7", " 8", " 9", "10", " J", " Q", " K"]
    
    var color:PokerColor
    var value:Int
    
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

extension Array where Element : PokerCard
{
    func sort()->[PokerCard]
    {
        return sortWithColor()
//        return sort({$0 > $1})
    }
    
    func sortWithColor()->[PokerCard]
    {
        return sorted(isOrderedBefore: { $0 != $1 ? $0 > $1 : $0.color.rawValue > $1.color.rawValue })
    }
    
    func toString() -> String
    {
        return map({$0.description}).joined(separator: " ")
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
