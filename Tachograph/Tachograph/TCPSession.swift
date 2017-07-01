//
//  TCPConnection.swift
//  Tachograph
//
//  Created by larryhou on 30/6/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation

@objc
protocol TCPSessionDelegate
{
    func tcp(session:TCPSession, data:Data)
    @objc optional func tcp(session:TCPSession, sendEvent:Stream.Event)
    @objc optional func tcp(session:TCPSession, readEvent:Stream.Event)
    @objc optional func tcp(session:TCPSession, error:Error)
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

class TCPSession:NSObject, StreamDelegate
{
    static let BUFFER_SIZE = 1024
    var delegate:TCPSessionDelegate?
    
    private var _readStream:InputStream!
    private var _sendStream:OutputStream!
    private var _timer:Timer!
    
    lazy
    private var _buffer:UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: BUFFER_SIZE)
    private var _queue:[QueuedMessage] = []
    
    var connected:Bool { return _flags == 0x11 }
    
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
        
        _flags = 0
        _timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }
    
    @objc func update()
    {
        guard let stream = _sendStream else { return }
        if stream.hasSpaceAvailable && _queue.count > 0
        {
            _flags |= 0x10
            send(_queue.removeFirst())
        }
    }
    
    private var _flags:Int = 0
    func stream(_ aStream: Stream, handle eventCode: Stream.Event)
    {
        print(eventCode)
        if aStream == _readStream
        {
            delegate?.tcp?(session: self, readEvent: eventCode)
            if eventCode == .hasBytesAvailable
            {
                _flags |= 0x01
                delegate?.tcp(session: self, data: read())
            }
        }
        else
        {
            delegate?.tcp?(session: self, sendEvent: eventCode)
        }
        
        if eventCode == .errorOccurred
        {
            if let error = aStream.streamError
            {
                print(error)
                delegate?.tcp?(session: self, error: error)
            }
            
            _flags = 0
            _timer.invalidate()
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
            print(String(data:bytes, encoding:.utf8)!)
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
            let num = _readStream.read(_buffer, maxLength: TCPSession.BUFFER_SIZE)
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
            let num = _readStream.read(_buffer, maxLength: min(remain, TCPSession.BUFFER_SIZE))
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
        _timer.invalidate()
    }
    
    deinit
    {
        close()
        
        _buffer.deallocate(capacity: TCPSession.BUFFER_SIZE)
    }
}
