//
//  ViewController.swift
//  Streams
//
//  Created by larryhou on 5/19/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController, NSStreamDelegate
{
    private var _data:NSMutableData!
    
    private var _input:NSInputStream!
    private var _output:NSOutputStream!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        readHttpInputStream()
    }
    
    func readFileInputStream()
    {
        let url = NSBundle.mainBundle().URLForResource("stars", withExtension: "xml")!
        
        let iStream = NSInputStream(URL: url)!
        iStream.delegate = self
        iStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        iStream.open()
    }
    
    func readHttpInputStream()
    {
        var readStream:Unmanaged<CFReadStream>?
        var writeStream:Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(nil, "www.qq.com", 80, &readStream, &writeStream)
        _input = readStream!.takeRetainedValue()
        _input.delegate = self
        _input.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
//        _input.setProperty("proxy.tencent.com", forKey: NSStreamSOCKSProxyHostKey)
//        _input.setProperty("8080", forKey: NSStreamSOCKSProxyPortKey)
        _input.open()
        
        _output = writeStream!.takeRetainedValue()
        _output.delegate = self
        _output.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        _output.open()
    }
    
    func stream(stream: NSStream, handleEvent eventCode: NSStreamEvent)
    {
        switch eventCode
        {
            case NSStreamEvent.OpenCompleted:
                println("OpenCompleted")
                _data = NSMutableData()
                break
            
            case NSStreamEvent.EndEncountered:
                println("EndEncountered")
//                disposeStream(stream)
                break
            
            case NSStreamEvent.ErrorOccurred:
                println("ErrorOccurred: \(stream.streamError!)")
                disposeStream(stream)
                break
            
            case NSStreamEvent.HasBytesAvailable:
                var buf = [UInt8](count: 1024, repeatedValue: 0)
                
                let input = stream as! NSInputStream
                let len = input.read(&buf, maxLength: buf.count)
                if len > 0
                {
                    _data.appendBytes(&buf, length: len)
                    println("Recieved: \(len)")
                }
                else
                {
                    println("Completed: \(_data.length)")
                    
                    var cfgbk = CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
                    let nsgbk = CFStringConvertEncodingToNSStringEncoding(cfgbk)
                    
                    let content = NSString(data: _data, encoding: nsgbk)!
                    println(content)
                    
                    NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "invokeHttpRequest", userInfo: nil, repeats: false)
                }
                break
            
            case NSStreamEvent.HasSpaceAvailable:
                println("HasSpaceAvailable")
                sendHttpRequest(stream as! NSOutputStream)
                break
            
            default:break
        }
    }
    
    func invokeHttpRequest()
    {
        println(__FUNCTION__)
        _output.delegate = self
        _output.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        _output.open()
    }
    
    func sendHttpRequest(output:NSOutputStream)
    {
        let header = "GET http://www.qq.com/ HTTP/1.0\r\n\r\n"
        var utf8 = [UInt8](header.utf8)
        
        output.write(&utf8, maxLength: utf8.count)
        output.close()
    }
    
    func disposeStream(stream:NSStream!)
    {
        if stream != nil
        {
            stream.close()
            stream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

