//
//  HandPatternTableCellView.swift
//  TexasHoldem
//
//  Created by larryhou on 12/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation
import UIKit

class PatternTableViewCell:UITableViewCell
{
    private static var color_hash:[HandPattern:UIColor]
    {
        var hash:[HandPattern:UIColor] = [:]
        hash[.HighCard]         = UIColor(white: 0.90, alpha: 1.0)
        hash[.OnePair]          = UIColor(white: 0.75, alpha: 1.0)
        hash[.TwoPair]          = UIColor(white: 0.50, alpha: 1.0)
        hash[.ThreeOfKind]      = UIColor(white: 0.00, alpha: 1.0)
        hash[.Straight]         = UIColor.greenColor()
        hash[.Flush]            = UIColor.blueColor()
        hash[.FullHouse]        = UIColor(red: 0.5, green: 0.0, blue: 1.0, alpha: 1.0)
        hash[.FourOfKind]       = UIColor.orangeColor()
        hash[.StraightFlush]    = UIColor.redColor()
        return hash
    }
    
    @IBOutlet weak var id: UILabel!
    @IBOutlet weak var pattern: UILabel!
    @IBOutlet weak var givenCards: UILabel!
    @IBOutlet weak var tableCards: UILabel!
    @IBOutlet weak var matchCards: UILabel!
    
    private var hand:PokerHand = PokerHand()
    
    func renderView(data:RawPokerHand)
    {
        PokerHand.parse(data.data, hand: hand)
        hand.evaluate()
        
        id.text = String(format: "%07d", data.index + 1)
        
        pattern.text = hand.pattern.description
        pattern.textColor = PatternTableViewCell.color_hash[hand.pattern]
        
        givenCards.text = hand.givenCards.toString()
        tableCards.text = hand.tableCards.toString()
        matchCards.text = hand.matches.toString()
    }
}
