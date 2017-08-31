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
    @objc optional func tcp(session:TCPSession, state:TCPSessionState)
    @objc optional func tcp(session:TCPSession, sendEvent:Stream.Event)
    @objc optional func tcp(session:TCPSession, readEvent:Stream.Event)
    @objc optional func tcp(session:TCPSession, error:Error)
    @objc optional func tcpUpdate(session:TCPSession)
    @objc optional func close()
}

extension Stream.Event
{
    var description:String
    {
        switch self
        {
            case .hasBytesAvailable:
                return "\(self) hasBytesAvailable"
            case .hasSpaceAvailable:
                return "\(self) hasSpaceAvailable"
            case .openCompleted:
                return "\(self) openCompleted"
            case .errorOccurred:
                return "\(self) errorOccurred"
            case .endEncountered:
                return "\(self) endEncountered"
            default:
                return "\(self)"
        }
    }
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

@objc
enum TCPSessionState:Int
{
    case none, connecting, connected, closed
}

class TCPSession:NSObject, StreamDelegate
{
    static let BUFFER_SIZE = 1024
    var delegate:TCPSessionDelegate?
    
    private var _readStream:InputStream!
    private var _sendStream:OutputStream!
    private var _timer:Timer!
    
    private var _state:TCPSessionState = .none
    private(set) var state:TCPSessionState
    {
        get {return _state}
        set
        {
            if _state != newValue
            {
                _state = newValue
                delegate?.tcp?(session: self, state: _state)
            }
        }
    }
    
    private var _buffer:UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: TCPSession.BUFFER_SIZE)
    private var _queue:[QueuedMessage] = []
    
    var connected:Bool { return _state == .connected }
    
    private var address:String?, port:UInt32 = 0
    func connect(address:String, port:UInt32)
    {
        self.address = address
        self.port = port
        
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
        
        state = .connecting
        
        _timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(sendUpdate), userInfo: nil, repeats: true)
    }
    
    func reconnect()
    {
        state = .connecting
        if let address = self.address, port != 0
        {
            close()
            connect(address: address, port: port)
        }
    }
    
    func clear()
    {
        _queue.removeAll()
    }
    
    @objc private func sendUpdate()
    {
        delegate?.tcpUpdate?(session: self)
        guard let stream = _sendStream else { return }
        if stream.hasSpaceAvailable
        {
            if !connected
            {
                state = .connected
            }
            
            if _queue.count > 0
            {
                send(_queue.removeFirst())
            }
        }
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event)
    {
        print(eventCode.description)
        if _readStream == nil || _sendStream == nil {return}
        if aStream == _readStream
        {
            delegate?.tcp?(session: self, readEvent: eventCode)
            if eventCode == .hasBytesAvailable
            {
                if let stream = _readStream, stream.hasBytesAvailable
                {
                    delegate?.tcp(session: self, data: read())
                }
            }
        }
        else
        {
            delegate?.tcp?(session: self, sendEvent: eventCode)
        }
        
        if eventCode == .errorOccurred || eventCode == .endEncountered
        {
            if let error = aStream.streamError
            {
                print(error)
                delegate?.tcp?(session: self, error: error)
            }
            
            close()
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
        while read(to: &data, size: TCPSession.BUFFER_SIZE) {}
        return data
    }
    
    @discardableResult
    private func read(to data: inout Data, size:Int)->Bool
    {
        guard let stream = _readStream, stream.hasBytesAvailable && stream.streamError == nil else { return false }
        let num = stream.read(_buffer, maxLength: size)
        if num > 0
        {
            data.append(_buffer, count: num)
            return true
        }
        else if let error = stream.streamError
        {
            close()
            print(error)
        }
        
        return false
    }
    
    func read(count:Int)->Data
    {
        var data = Data()
        
        var bytesAvailable = true
        while bytesAvailable
        {
            let remain = count - data.count
            bytesAvailable = read(to: &data, size: min(remain, TCPSession.BUFFER_SIZE))
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
        
        state = .closed
        delegate?.close?()
    }
    
    deinit
    {
        close()
        
        _buffer.deallocate(capacity: TCPSession.BUFFER_SIZE)
    }
}
