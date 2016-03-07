//
//  ViewController.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{

    override func viewDidLoad()
    {
        super.viewDidLoad()
        print(HandV1HighCard().toString())
        print(HandV2OnePair().toString())
        print(HandV3TwoPair().toString())
        print(HandV4TreeOfKind().toString())
        print(HandV5Straight().toString())
        print(HandV6Flush().toString())
        print(HandV7FullHouse().toString())
        print(HandV8FourOfKind().toString())
        print(HandV9StraightFlush().toString())
        
        var givenCards = [PokerCard]()
        givenCards.append(PokerCard(color: PokerColor.Spade, value: 1))
        givenCards.append(PokerCard(color: PokerColor.Club, value: 3))
        
        var tableCards = [PokerCard]()
        tableCards.append(PokerCard(color: PokerColor.Spade, value: 2))
        tableCards.append(PokerCard(color: PokerColor.Diamond, value: 2))
        tableCards.append(PokerCard(color: PokerColor.Heart, value: 1))
        tableCards.append(PokerCard(color: PokerColor.Club, value: 9))
        tableCards.append(PokerCard(color: PokerColor.Club, value: 1))
        tableCards.append(PokerCard(color: PokerColor.Spade, value: 3))
        
        let hand = HoldemHand(givenCards: givenCards, tableCards: tableCards)
        if HandV7FullHouse.match(hand)
        {
            print(hand.pattern, hand.matches.toString())
        }
        
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

