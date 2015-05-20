//
//  ByteArray.swift
//  ByteArray
//
//  Created by larryhou on 5/20/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import Foundation

class ByteArray
{
    enum Endian:Int
    {
        case LITTLE_ENDIAN = 1 // NS_LittleEndian
        case BIG_ENIDAN = 2 // NS_BigEndian
    }
    
    //MARK: properties
    var data:NSMutableData!
    var length:Int {return data == nil ? 0 : data.length }
    
    var endian:Endian  = Endian.LITTLE_ENDIAN
    var position:Int = 0
    
    var bytesAvailable:Bool {return position < length}
    
    //MARK: position
    private var range:NSRange = NSRange(location: 0, length: 0)
    
    //MARK: subscript
    subscript(index:Int)->UInt8
    {
        var value:UInt8 = 0
        data.getBytes(&value, range: NSRange(location: index, length: 1))
        return value
    }
    
    //MARK: ByteArray read
    func readBoolean()->Bool
    {
        range.location = position
        range.length = 1
        
        var flag = false
        data.getBytes(&flag, range: range)
        position += range.length
        return flag
    }
    
    func readDouble()->Double
    {
        range.location = position
        range.length = 8
        
        var value:Double = 0.0
        if endian == Endian.BIG_ENIDAN
        {
            var bytes = [UInt8](count: range.length, repeatedValue: 0)
            data.getBytes(&bytes, range: range)
            bytes.reverse()
            
            value = UnsafePointer<Double>(bytes).memory
        }
        else
        {
            data.getBytes(&value, range: range)
        }
        
        position += range.length
        return value
    }
    
    func readFloat()->Float32
    {
        range.location = position
        range.length = 4
        
        var value:Float32 = 0.0
        if endian == Endian.BIG_ENIDAN
        {
            var bytes = [UInt8](count: range.length, repeatedValue: 0)
            data.getBytes(&bytes, range: range)
            bytes.reverse()
            
            value = UnsafePointer<Float32>(bytes).memory
        }
        else
        {
            data.getBytes(&value, range: range)
        }
        
        position += range.length
        return value
    }
    
    func readInt8()->Int8
    {
        range.location = position
        range.length = 1
        
        var value:Int8 = 0
        data.getBytes(&value, range: range)
        position += range.length
        return value
    }
    
    func readInt16()->Int16
    {
        range.location = position
        range.length = 2
        
        var value:Int16 = 0
        data.getBytes(&value, range: range)
        position += range.length
        return endian == Endian.BIG_ENIDAN ? value.bigEndian : value
    }
    
    func readInt32()->Int32
    {
        range.location = position
        range.length = 4
        
        var value:Int32 = 0
        data.getBytes(&value, range: range)
        position += range.length
        return endian == Endian.BIG_ENIDAN ? value.bigEndian : value
    }
    
    func readInt64()->Int
    {
        range.location = position
        range.length = 8
        
        var value:Int = 0
        data.getBytes(&value, range: range)
        position += range.length
        return endian == Endian.BIG_ENIDAN ? value.bigEndian : value
    }
    
    func readUInt8()->UInt8
    {
        range.location = position
        range.length = 1
        
        var value:UInt8 = 0
        data.getBytes(&value, range: range)
        position += range.length
        return value
    }
    
    func readUInt16()->UInt16
    {
        range.location = position
        range.length = 2
        
        var value:UInt16 = 0
        data.getBytes(&value, range: range)
        position += data.length
        return endian == Endian.BIG_ENIDAN ? value.bigEndian : value
    }
    
    func readUInt32()->UInt32
    {
        range.location = position
        range.length = 4
        
        var value:UInt32 = 0
        data.getBytes(&value, range: range)
        position += data.length
        return endian == Endian.BIG_ENIDAN ? value.bigEndian : value
    }
    
    func readUInt64()->UInt
    {
        range.location = position
        range.length = 8
        
        var value:UInt = 0
        data.getBytes(&value, range: range)
        position += data.length
        return endian == Endian.BIG_ENIDAN ? value.bigEndian : value
    }
    
    func readBytes(bytes:ByteArray, offset:Int = 0, var length:Int = 0)
    {
        let remain = max(0, self.length - self.position)
        
        length = length == 0 ? remain : min(length, remain)
        if length <= 0
        {
            return
        }
        
        range.location = position
        range.length = length
        
        let data = self.data.subdataWithRange(range)
        position += range.length
        
        var buffer = NSMutableData()
        if offset >= bytes.length
        {
            buffer.appendData(bytes.data)
            if offset > bytes.length
            {
                var padding = [UInt8](count: offset - bytes.length, repeatedValue: 0)
                buffer.appendBytes(&padding, length: padding.count)
            }
            
            buffer.appendData(data)
        }
        else
        {
            let head = bytes.data.subdataWithRange(NSRange(location: 0, length: offset))
            buffer.appendData(head)
            buffer.appendData(data)
            if offset + length < bytes.length
            {
                let tail = bytes.data.subdataWithRange(NSRange(location: offset + length, length: bytes.length - (offset + length)))
                buffer.appendData(tail)
            }
        }
        
        bytes.data = buffer
    }
    
    func readUTF()->String
    {
        return readUTFBytes(Int(readInt16()))
    }
    
    func readUTFBytes(length:Int)->String
    {
        range.location = position
        range.length = length
        
        let value = NSString(data: data.subdataWithRange(range), encoding: NSUTF8StringEncoding) as! String
        position += range.length
        return value
    }
    
    func readMultiByte(length:Int, encoding:CFStringEncoding)->String
    {
        range.location = position
        range.length = length
        
        let charset = CFStringConvertEncodingToNSStringEncoding(encoding)
        let value = NSString(data: data.subdataWithRange(range), encoding: charset) as! String
        position += range.length
        return value
    }
    
    //MARK: dump
    
    func dump<T>(var target:T)->[UInt8]
    {
        return withUnsafePointer(&target)
        {
            let bufpt = UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(T))
            return Array(bufpt)
        }
    }
    
    //MARK: ByteArray write
    
    func writeBoolean(var value:Bool)
    {
        data.appendBytes(&value, length: 1)
        position++
    }
    
    func writeDouble(var value:Double)
    {
        let num = 8
        if endian == Endian.BIG_ENIDAN
        {
            var bytes = self.dump(value)
            bytes.reverse()
            
            data.appendBytes(&bytes, length: bytes.count)
        }
        else
        {
            data.appendBytes(&value, length: num)
        }
        
        position += num
    }
    
    func writeFloat(var value:Float32)
    {
        let num = 4
        if endian == Endian.BIG_ENIDAN
        {
            var bytes = self.dump(value)
            bytes.reverse()
            
            data.appendBytes(&bytes, length: bytes.count)
        }
        else
        {
            data.appendBytes(&value, length: num)
        }
        
        position += num
    }
    
    func writeInt8(var value:Int8)
    {
        data.appendBytes(&value, length: 1)
        position++
    }
    
    func writeInt16(var value:Int16)
    {
        if endian == Endian.BIG_ENIDAN
        {
            value = value.bigEndian
        }
        
        let num = 2
        data.appendBytes(&value, length: num)
        position += num
    }
    
    func writeInt32(var value:Int32)
    {
        if endian == Endian.BIG_ENIDAN
        {
            value = value.bigEndian
        }
        
        let num = 4
        data.appendBytes(&value, length: num)
        position += num
    }
    
    func writeInt64(var value:Int)
    {
        if endian == Endian.BIG_ENIDAN
        {
            value = value.bigEndian
        }
        
        let num = 8
        data.appendBytes(&value, length: num)
        position += num
    }
    
    func writeUInt8(var value:UInt8)
    {
        data.appendBytes(&value, length: 1)
        position++
    }
    
    func writeUInt16(var value:UInt16)
    {
        if endian == Endian.BIG_ENIDAN
        {
            value = value.bigEndian
        }
        
        let num = 2
        data.appendBytes(&value, length: num)
        position += num
    }
    
    func writeUInt32(var value:UInt32)
    {
        if endian == Endian.BIG_ENIDAN
        {
            value = value.bigEndian
        }
        
        let num = 4
        data.appendBytes(&value, length: num)
        position += num
    }
    
    func writeUInt64(var value:UInt64)
    {
        if endian == Endian.BIG_ENIDAN
        {
            value = value.bigEndian
        }
        
        let num = 8
        data.appendBytes(&value, length: num)
        position += num
    }
    
    func writeUTF(var value:String)
    {
        var num = UInt16(count(value.utf8))
        data.appendBytes(&num, length: 2)
        position += 2
        
        writeUTFBytes(value)
    }
    
    func writeUTFBytes(var value:String)
    {
        let data = NSString(string: value).dataUsingEncoding(NSUTF8StringEncoding)!
        self.data.appendData(data)
        
        position += data.length
    }
    
    func writeMultiBytes(var value:String, encoding:CFStringEncoding)
    {
        let chatset = CFStringConvertEncodingToNSStringEncoding(encoding)
        let data = NSString(string: value).dataUsingEncoding(chatset)!
        self.data.appendData(data)
        
        position += data.length
    }
    
    func writeBytes(bytes:ByteArray, offset:Int = 0, var length:Int = 0)
    {
        let remain = max(0, bytes.length - offset)
        
        length = length == 0 ? remain : min(length, remain)
        if length > 0
        {
            let data = bytes.data.subdataWithRange(NSRange(location: offset, length: length))
            self.data.appendData(data)
            position += data.length
        }
    }
}