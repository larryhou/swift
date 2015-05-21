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
        case BIG_ENDIAN = 2 // NS_BigEndian
    }
    
    var endian:Endian
    var data:NSMutableData
    var position:Int
    
    private var range:NSRange
    
    var length:Int {return data.length }
    var bytesAvailable:Bool {return position < length}
    
    init()
    {
        data = NSMutableData()
        endian = Endian.LITTLE_ENDIAN
        range = NSRange(location: 0, length: 0)
        position = 0
    }
    
    convenience init(data:NSData)
    {
        self.init()
        self.data.appendData(data)
    }
    
    //MARK: subscript
    subscript(index:Int)->UInt8
    {
        var value:UInt8 = 0
        data.getBytes(&value, range: NSRange(location: index, length: 1))
        return value
    }
    
    //MARK: clear
    func clear()
    {
        data = NSMutableData()
        position = 0
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
        if endian == Endian.BIG_ENDIAN
        {
            var bytes = [UInt8](count: range.length, repeatedValue: 0)
            data.getBytes(&bytes, range: range)
            bytes = bytes.reverse()
            
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
        if endian == Endian.BIG_ENDIAN
        {
            var bytes = [UInt8](count: range.length, repeatedValue: 0)
            data.getBytes(&bytes, range: range)
            bytes = bytes.reverse()
            
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
        return endian == Endian.BIG_ENDIAN ? value.bigEndian : value
    }
    
    func readInt32()->Int32
    {
        range.location = position
        range.length = 4
        
        var value:Int32 = 0
        data.getBytes(&value, range: range)
        position += range.length
        return endian == Endian.BIG_ENDIAN ? value.bigEndian : value
    }
    
    func readInt64()->Int
    {
        range.location = position
        range.length = 8
        
        var value:Int = 0
        data.getBytes(&value, range: range)
        position += range.length
        return endian == Endian.BIG_ENDIAN ? value.bigEndian : value
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
        return endian == Endian.BIG_ENDIAN ? value.bigEndian : value
    }
    
    func readUInt32()->UInt32
    {
        range.location = position
        range.length = 4
        
        var value:UInt32 = 0
        data.getBytes(&value, range: range)
        position += data.length
        return endian == Endian.BIG_ENDIAN ? value.bigEndian : value
    }
    
    func readUInt64()->UInt
    {
        range.location = position
        range.length = 8
        
        var value:UInt = 0
        data.getBytes(&value, range: range)
        position += data.length
        return endian == Endian.BIG_ENDIAN ? value.bigEndian : value
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
        
        var list = [UInt8](count: range.length, repeatedValue: 0)
        data.getBytes(&list, range: range)
        position += range.length
        
        var bin = bytes.data
        if offset > bytes.length
        {
            var zeros = [UInt8](count: offset - bytes.length, repeatedValue: 0)
            bin.replaceBytesInRange(NSRange(location: bytes.length, length: zeros.count), withBytes: &zeros)
        }
        
        bin.replaceBytesInRange(NSRange(location: offset, length: length), withBytes: &list)
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
    
    //MARK: class tools
    
    class func dump<T>(var target:T)->[UInt8]
    {
        return withUnsafePointer(&target)
        {
            let bufpt = UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(T))
            return Array(bufpt)
        }
    }
    
    class func hexe(bytes:ByteArray, var range:NSRange, column:Int = 4)->String
    {
        if range.location + range.length > bytes.length
        {
            range.length = bytes.length - range.location
        }
        
        var list = [UInt8](count: range.length, repeatedValue: 0)
        bytes.data.getBytes(&list, range: range)
        
        var result = ""
        var data = list.map({String(format:"%02x", $0).uppercaseString})
        for i in 0..<data.count
        {
            result += data[i] + " "
            if (i + 1) % 4 == 0
            {
                result += " "
                if (i + 1) % (4 * column) == 0
                {
                    result += "\n"
                }
            }
        }
        
        return result
    }
    
    //MARK: ByteArray write
    
    func writeBoolean(var value:Bool)
    {
        range.location = position
        range.length = 1
        
        data.replaceBytesInRange(range, withBytes: &value)
        position += range.length
    }
    
    func writeDouble(var value:Double)
    {
        range.location = position
        range.length = 8
        
        if endian == Endian.BIG_ENDIAN
        {
            var bytes = ByteArray.dump(value)
            bytes = bytes.reverse()
            
            data.replaceBytesInRange(range, withBytes: &bytes)
        }
        else
        {
            data.replaceBytesInRange(range, withBytes: &value)
        }
        
        position += range.length
    }
    
    func writeFloat(var value:Float32)
    {
        range.location = position
        range.length = 4
        
        if endian == Endian.BIG_ENDIAN
        {
            var bytes = ByteArray.dump(value)
            bytes = bytes.reverse()
            
            data.replaceBytesInRange(range, withBytes: &bytes)
        }
        else
        {
            data.replaceBytesInRange(range, withBytes: &value)
        }
        
        position += range.length
    }
    
    func writeInt8(var value:Int8)
    {
        range.location = position
        range.length = 1
        
        data.replaceBytesInRange(range, withBytes: &value)
        position += range.length
    }
    
    func writeInt16(var value:Int16)
    {
        if endian == Endian.BIG_ENDIAN
        {
            value = value.bigEndian
        }
        
        range.location = position
        range.length = 2
        
        data.replaceBytesInRange(range, withBytes: &value)
        position += range.length
    }
    
    func writeInt32(var value:Int32)
    {
        if endian == Endian.BIG_ENDIAN
        {
            value = value.bigEndian
        }
        
        range.location = position
        range.length = 4
        
        data.replaceBytesInRange(range, withBytes: &value)
        position += range.length
    }
    
    func writeInt64(var value:Int)
    {
        if endian == Endian.BIG_ENDIAN
        {
            value = value.bigEndian
        }
        
        range.location = position
        range.length = 8
        
        data.replaceBytesInRange(range, withBytes: &value)
        position += range.length
    }
    
    func writeUInt8(var value:UInt8)
    {
        range.location = position
        range.length = 1
        
        data.replaceBytesInRange(range, withBytes: &value)
        position += range.length
    }
    
    func writeUInt16(var value:UInt16)
    {
        if endian == Endian.BIG_ENDIAN
        {
            value = value.bigEndian
        }
        
        range.location = position
        range.length = 2
        
        data.replaceBytesInRange(range, withBytes: &value)
        position += range.length
    }
    
    func writeUInt32(var value:UInt32)
    {
        if endian == Endian.BIG_ENDIAN
        {
            value = value.bigEndian
        }
        
        range.location = position
        range.length = 4
        
        data.replaceBytesInRange(range, withBytes: &value)
        position += range.length
    }
    
    func writeUInt64(var value:UInt)
    {
        if endian == Endian.BIG_ENDIAN
        {
            value = value.bigEndian
        }
        
        range.location = position
        range.length = 8
        
        data.replaceBytesInRange(range, withBytes: &value)
        position += range.length
    }
    
    func writeUTF(var value:String)
    {
        var num = UInt16(count(value.utf8))
        if endian == Endian.BIG_ENDIAN
        {
            num = num.bigEndian
        }
        
        range.location = position
        range.length = 2
        
        data.replaceBytesInRange(range, withBytes: &num)
        position += range.length
        
        writeUTFBytes(value)
    }
    
    func writeUTFBytes(var value:String)
    {
        var bytes = [UInt8](value.utf8)
        
        range.location = position
        range.length = bytes.count
        
        data.replaceBytesInRange(range, withBytes: &bytes)
        position += range.length
    }
    
    func writeMultiBytes(var value:String, encoding:CFStringEncoding)
    {
        let chatset = CFStringConvertEncodingToNSStringEncoding(encoding)
        let bin = NSString(string: value).dataUsingEncoding(chatset)!
        
        var bytes = [UInt8](count: bin.length, repeatedValue: 0)
        bin.getBytes(&bytes, length: bytes.count)
        
        range.location = position
        range.length = bin.length
        
        data.replaceBytesInRange(range, withBytes: &bytes)
        position += range.length
    }
    
    func writeBytes(bytes:ByteArray, offset:Int = 0, var length:Int = 0)
    {
        let remain = max(0, bytes.length - offset)
        
        length = length == 0 ? remain : min(length, remain)
        if length > 0
        {
            let bin = bytes.data.subdataWithRange(NSRange(location: offset, length: length))
            
            var bytes = [UInt8](count: bin.length, repeatedValue: 0)
            bin.getBytes(&bytes, length: bytes.count)
            
            range.location = position
            range.length = bin.length
            
            data.replaceBytesInRange(range, withBytes: &bytes)
            position += range.length
        }
    }
}