//
//  InstancePool.swift
//  Tachograph
//
//  Created by larryhou on 03/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation

@objc protocol ReusableObject
{
    static func instantiate(_ data:Any?)->ReusableObject
    @objc optional func recycle()
    @objc optional func fetch()
    @objc optional func clear()
}

class InstanceManager<T> where T:ReusableObject & Equatable
{
    private var manager:[T] = []
    
    init()
    {
        
    }
    
    func fetch<X>(_ data:X? = nil)->T
    {
        let target:T
        if manager.count > 0
        {
            target = manager.removeLast()
        }
        else
        {
            target = T.instantiate(data) as! T
        }
        target.fetch?()
        return target
    }
    
    func recycle(target:T)
    {
        target.recycle?()
        if !manager.contains{ $0 == target }
        {
            manager.append(target)
        }
    }
    
    func clear()
    {
        while manager.count > 0
        {
            manager.remove(at: 0).clear?()
        }
    }
    
    deinit
    {
        self.clear()
    }
}
