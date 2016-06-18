//
//  Math.swift
//  TexasHoldem
//
//  Created by larryhou on 6/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

func combinate(_ num:UInt, select:UInt) -> UInt
{
    return permutate(num, select: select) / permuate(select)
}

func permutate(_ num:UInt, select:UInt) -> UInt
{
    var result:UInt = 1
    
    for i in 0..<select
    {
        result *= num - i
    }
    
    return result
}

func permuate(_ num:UInt) -> UInt
{
    var result:UInt = 1
    for i in 0..<num
    {
        result *= num - i
    }
    
    return result
}

func pow(_ base:UInt, exponent:UInt) -> UInt
{
    var result:UInt = 1
    for _ in 1...exponent
    {
        result *= base
    }
    
    return result
}

extension UInt
{
    var double:Double
    {
        return Double(self)
    }
}
