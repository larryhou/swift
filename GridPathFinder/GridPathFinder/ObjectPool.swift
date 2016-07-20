//
//  ObjectPool.swift
//  GridPathFinder
//
//  Created by larryhou on 7/20/16.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation

protocol IPoolObject
{
    init()
    func awake()
    func recycle()
}

class ObjectPool<T> where T:IPoolObject, T:Equatable
{
    private var pool:[T]
    
    init()
    {
        self.pool = []
    }
    
    func get()->T
    {
        return get{T()}
    }
    
    func get(_ getobj:@noescape ()->T)->T
    {
        let object:T
        if pool.count > 0
        {
            object = pool.removeLast()
        }
        else
        {
            object = getobj()
        }
        
        object.awake()
        return object
    }
    
    func recycle(_ object:T)
    {
        object.recycle()
        if let index = pool.index(of: object) where index >= 0
        {
            pool.append(object)
        }
    }
    
    func clear()
    {
        pool.removeAll()
    }
}
