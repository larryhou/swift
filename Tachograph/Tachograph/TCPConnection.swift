//
//  TCPConnection.swift
//  Tachograph
//
//  Created by larryhou on 30/6/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation

@objc
protocol TCPConnectionDelegate
{
    func tcp(connection:TCPConnection, data:Data)
    @objc optional func tcp(connection:TCPConnection, sendEvent:Stream.Event)
    @objc optional func tcp(connection:TCPConnection, readEvent:Stream.Event)
}

struct QueuedMessage
{
    let data:Data
    let count:Int
    let offset:Int
    
    init(data:Data)
    {
        self.init(data: data, offset: -1, count: -1)
    }
    
    init(data:Data, count:Int)
    {
        self.init(data: data, offset: -1, count: count)
    }
    
    init(data:Data, offset:Int, count:Int)
    {
        self.data = data
        self.count = count
        self.offset = offset
    }
}

class TCPConnection:NSObject, StreamDelegate
{
    static let BUFFER_SIZE = 1024
    
    var delegate:TCPConnectionDelegate?
    
    private var _readStream:InputStream!
    private var _sendStream:OutputStream!
    
    lazy
    private var _buffer:UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: BUFFER_SIZE)
    private var _queue:[QueuedMessage] = []
    
    func connect(address:String, port:UInt32)
    {
        var r:Unmanaged<CFReadStream>?
        var w:Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocketToHost(nil, address as CFString, port, &r, &w)
        
        _readStream = r!.takeRetainedValue() as InputStream
        _readStream.delegate = self
        
        _sendStream = w!.takeRetainedValue() as OutputStream
        _sendStream.delegate = self
        
        _readStream.schedule(in: .current, forMode: .defaultRunLoopMode)
        _sendStream.schedule(in: .current, forMode: .defaultRunLoopMode)
        
        _readStream.open()
        _sendStream.open()
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event)
    {
        if aStream == _readStream
        {
            delegate?.tcp?(connection: self, readEvent: eventCode)
            if eventCode == .hasBytesAvailable
            {
                delegate?.tcp(connection: self, data: read())
            }
        }
        else
        {
            delegate?.tcp?(connection: self, sendEvent: eventCode)
            if eventCode == .hasSpaceAvailable && _queue.count > 0
            {
                send(_queue.removeFirst())
            }
        }
        
        if eventCode == .errorOccurred
        {
            if let error = aStream.streamError
            {
                print(error)
            }
        }
    }
    
    func send(data:String)
    {
        if let data = data.data(using: .utf8)
        {
            send(data: data)
        }
    }
    
    func send(data:Dictionary<String, Any>)
    {
        do
        {
            let bytes = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            send(data: bytes)
        }
        catch
        {
            print(error)
        }
    }
    
    func send(data:Data)
    {
        _queue.append(QueuedMessage(data: data))
    }
    
    func send(data:Data, count:Int)
    {
        _queue.append(QueuedMessage(data: data, count: count))
    }
    
    @discardableResult
    private func send(_ msg:QueuedMessage) -> Int
    {
        let data = msg.data
        
        var count = msg.count
        if msg.count <= -1
        {
            count = msg.data.count
        }
        
        if msg.offset <= -1
        {
            return data.withUnsafeBytes { (pointer:UnsafePointer<UInt8>) in
                _sendStream.write(pointer, maxLength: min(count, data.count))
            }
        }
        else
        {
            let offset = msg.offset
            return data.withUnsafeBytes { (pointer:UnsafePointer<UInt8>) in
                let new = pointer.advanced(by: offset)
                let num = min(data.count - offset, count)
                return _sendStream.write(new, maxLength: num)
            }
        }
    }
    
    func send(data:Data, offset:Int, count:Int)
    {
        _queue.append(QueuedMessage(data: data, offset: offset, count: count))
    }
    
    func read()->Data
    {
        var data = Data()
        while _readStream.hasBytesAvailable
        {
            let num = _readStream.read(_buffer, maxLength: TCPConnection.BUFFER_SIZE)
            data.append(_buffer, count: num)
        }
        return data
    }
    
    func read(count:Int)->Data
    {
        var data = Data()
        while _readStream.hasBytesAvailable
        {
            let remain = count - data.count
            let num = _readStream.read(_buffer, maxLength: min(remain, TCPConnection.BUFFER_SIZE))
            data.append(_buffer, count: num)
        }
        return data
    }
    
    func close()
    {
        if _readStream != nil
        {
            _readStream.close()
            _readStream = nil
        }
        
        if _sendStream != nil
        {
            _sendStream.close()
            _sendStream = nil
        }
        
        _queue.removeAll(keepingCapacity: false)
    }
    
    deinit
    {
        close()
        
        _buffer.deallocate(capacity: TCPConnection.BUFFER_SIZE)
    }
}
