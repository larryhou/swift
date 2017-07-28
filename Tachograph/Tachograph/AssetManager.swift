//
//  ResourceLoader.swift
//  Tachograph
//
//  Created by larryhou on 7/7/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation

class AssetManager:NSObject, URLSessionDownloadDelegate
{
    class AssetProgression:Codable
    {
        let url, name:String
        var bytesWritten, bytesExpectedTotal:Int64
        
        init(url:String)
        {
            self.url = url
            self.name = String(url.split(separator: "/").last!)
            self.bytesExpectedTotal = 0
            self.bytesWritten = 0
        } 
    }
    
    static private(set) var shared:AssetManager = AssetManager()
    typealias LoadCompleteHandler = (String, Data)->Void
    typealias LoadProgressHandler = (String, Float)->Void
    
    private var progress:[String:AssetProgression] = [:]
    private var handlers:[String:(LoadCompleteHandler?, LoadProgressHandler?)] = [:]
    private var tasks:[String:URLSessionDownloadTask] = [:]
    
    var session:URLSession!
    
    private func locate(append:String? = nil)->URL
    {
        var location = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        if let pathComponent = append
        {
            location.appendPathComponent(pathComponent)
        }
        return location
    }
    
    //MARK: session delegate
    @available(iOS 7.0, *)
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        if let url = downloadTask.originalRequest?.url
        {
            let name:String = self.name(from: url.absoluteString)
            defer
            {
                handlers.removeValue(forKey: name)
                progress.removeValue(forKey: name)
                tasks.removeValue(forKey: name)
            }
            
            if let data = try? Data(contentsOf: location)
            {
                handlers[name]?.0?(name, data)
                
                let destination = locate(append: name)
                try? data.write(to: destination)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64)
    {
        if let url = downloadTask.originalRequest?.url
        {
            let name:String = self.name(from: url.absoluteString)
            if let item = progress[name]
            {
                item.bytesWritten = fileOffset
                item.bytesExpectedTotal = expectedTotalBytes
                handlers[name]?.1?(name, get(progress: item))
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        if let url = downloadTask.originalRequest?.url
        {
            let name:String = self.name(from: url.absoluteString)
            if let item = progress[name]
            {
                item.bytesWritten = totalBytesWritten
                item.bytesExpectedTotal = totalBytesExpectedToWrite
                handlers[name]?.1?(name, get(progress: item))
            }
        }
    }
    
    //MARK: manager
    func get(progress name:String)->Float
    {
        if let item = progress[name]
        {
            return get(progress:item)
        }
        
        return Float.nan
    }
    
    private func get(progress item:AssetProgression)->Float
    {
        return (Float)(Double(item.bytesWritten) / Double(item.bytesExpectedTotal))
    }
    
    func name(from url:String)->String
    {
        return String(url.split(separator: "/").last!)
    }
    
    func get(url:String)->URL?
    {
        let location = locate(append: name(from: url))
        if FileManager.default.fileExists(atPath: location.path)
        {
            return location
        }
        return nil
    }
    
    func has(url:String)->Bool
    {
        let location = locate(append: name(from: url))
        return FileManager.default.fileExists(atPath: location.path)
    }
    
    private func writeResumeData(_ data:Data, name:String)
    {
        let location = locate(append: "\(name).dl")
        try? data.write(to: location)
    }
    
    private func readResumeData(name:String, deleteAfterReading:Bool = true)->Data?
    {
        let location = locate(append: "\(name).dl")
        let data = try? Data(contentsOf: location)
        if deleteAfterReading
        {
            try? FileManager.default.removeItem(at: location)
        }
        return data
    }
    
    func cancel(url:String)
    {
        let name:String = self.name(from: url)
        if let task = tasks[name]
        {
            task.cancel()
            { [unowned self] (data) in
                if let data = data
                {
                    self.writeResumeData(data, name: name)
                }
            }
        }
    }
    
    func resume(url:String)
    {
        let name:String = self.name(from: url)
        if let task = tasks[name]
        {
            task.resume()
        }
    }
    
    func suspend(url:String)
    {
        let name:String = self.name(from: url)
        if let task = tasks[name]
        {
            task.suspend()
        }
    }
    
    func load(url:String, completion completeHandler:LoadCompleteHandler?, progression progressHandler:LoadProgressHandler? = nil)
    {
        if self.session == nil
        {
            self.session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: .main)
        }
        
        if let url = URL(string: url)
        {
            let item = AssetProgression(url: url.absoluteString)
            handlers[item.name] = (completeHandler, progressHandler)
            progress[item.name] = item
            
            let task:URLSessionDownloadTask
            if let data = readResumeData(name: item.name)
            {
                task = session.downloadTask(withResumeData: data)
            }
            else
            {
                task = session.downloadTask(with: url)
            }
            tasks[item.name] = task
            task.resume()
        }
    }
}
