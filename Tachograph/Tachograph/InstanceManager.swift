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
    @objc optional func dispose()
}

class InstanceManager<T> where T:ReusableObject & Equatable
{
    private var manager:[T] = []
    private var instances:[T] = []
    private var instanceCount:Int {return instances.count}
    private(set) var recycledCount = 0
    private(set) var reusedCount = 0
    
    init()
    {
        
    }
    
    func spawn<X>(_ data:X? = nil, count:Int)
    {
        for _ in 0..<count
        {
            let target = T.instantiate(data) as! T
            instances.append(target)
            manager.append(target)
        }
    }
    
    func fetch<X>(_ data:X? = nil)->T
    {
        let target:T
        if manager.count > 0
        {
            reusedCount += 1
            target = manager.remove(at: 0)
        }
        else
        {
            target = T.instantiate(data) as! T
            instances.append(target)
        }
        target.fetch?()
        return target
    }
    
    func recycle(target:T)
    {
        if !manager.contains{ $0 == target }
        {
            recycledCount += 1
            manager.append(target)
            target.recycle?()
        }
    }
    
    func clear()
    {
        while manager.count > 0
        {
            manager.remove(at: 0).clear?()
        }
        
        recycledCount = 0
        reusedCount = 0
    }
    
    func dispose()
    {
        clear()
        while instances.count > 0
        {
            instances.remove(at: 0).dispose?()
        }
    }
    
    deinit
    {
        self.dispose()
    }
}
