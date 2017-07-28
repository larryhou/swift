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
            let name:String = get(name: url.absoluteString)
            defer
            {
                clean(name: name)
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
            let name:String = get(name: url.absoluteString)
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
            let name:String = get(name: url.absoluteString)
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
    
    private func get(name url:String)->String
    {
        return String(url.split(separator: "/").last!)
    }
    
    func get(cache url:String)->URL?
    {
        let location = locate(append: get(name: url))
        if FileManager.default.fileExists(atPath: location.path)
        {
            return location
        }
        return nil
    }
    
    func has(cache url:String)->Bool
    {
        let location = locate(append: get(name: url))
        return FileManager.default.fileExists(atPath: location.path)
    }
    
    private func writeResumeData(_ data:Data, name:String)
    {
        let location = locate(append: "\(name).dl")
        try? data.write(to: location)
    }
    
    private func readResumeData(name:String)->Data?
    {
        let location = locate(append: "\(name).dl")
        let data = try? Data(contentsOf: location)
        try? FileManager.default.removeItem(at: location)
        return data
    }
    
    func cancel(url:String, resumable:Bool = true)
    {
        let name:String = get(name: url)
        if let task = tasks[name]
        {
            if resumable
            {
                task.cancel()
                { [unowned self] (data) in
                    if let data = data
                    {
                        self.writeResumeData(data, name: name)
                    }
                }
            }
            else
            {
                task.cancel()
            }
            clean(name: name)
        }
    }
    
    private func clean(name:String)
    {
        handlers.removeValue(forKey: name)
        progress.removeValue(forKey: name)
        tasks.removeValue(forKey: name)
    }
    
    func removeUserStorage()
    {
        let location = locate()
        if let list = try? FileManager.default.contentsOfDirectory(at: location, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
        {
            list.forEach({ try? FileManager.default.removeItem(at: $0) })
        }
    }
    
    func resume(url:String)
    {
        let name:String = get(name: url)
        if let task = tasks[name]
        {
            task.resume()
        }
    }
    
    func suspend(url:String)
    {
        let name:String = get(name: url)
        if let task = tasks[name]
        {
            task.suspend()
        }
    }
    
    func has(task url:String)->Bool
    {
        let name = get(name: url)
        return tasks[name] != nil
    }
    
    func load(url:String, completion completeHandler:LoadCompleteHandler?, progression progressHandler:LoadProgressHandler? = nil)
    {
        if self.session == nil
        {
            self.session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: .main)
        }
        
        if let url = URL(string: url)
        {
            let name = get(name: url.absoluteString)
            handlers[name] = (completeHandler, progressHandler)
            if let task = tasks[name]
            {
                if task.state == .suspended
                {
                    resume(url: url.absoluteString)
                }
                return
            }
            
            let item = AssetProgression(url: url.absoluteString)
            progress[name] = item
            
            let task:URLSessionDownloadTask
            if let data = readResumeData(name: name)
            {
                task = session.downloadTask(withResumeData: data)
            }
            else
            {
                task = session.downloadTask(with: url)
            }
            tasks[name] = task
            task.resume()
        }
    }
}
