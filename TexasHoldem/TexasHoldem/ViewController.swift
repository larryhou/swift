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
        
        let result = PokerDealer.deal(10)
        for i in 0..<result.count
        {
            result[i].evaluate()
            print(result[i].description)
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

