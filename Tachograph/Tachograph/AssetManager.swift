//
//  ResourceLoader.swift
//  Tachograph
//
//  Created by larryhou on 7/7/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation

class AssetManager:NSObject
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
    static let identifier:String = "assets.download"
    
    static private(set) var shared:AssetManager = AssetManager()
    typealias LoadCompleteHandler = (String, Data)->Void
    typealias LoadProgressHandler = (String, Float)->Void
    
    private var progress:[String:AssetProgression] = [:]
    private var handlers:[String:(LoadCompleteHandler?, LoadProgressHandler?)] = [:]
    private var tasks:[String:URLSessionDownloadTask] = [:]
    
    var externalCompletion:(()->Void)?
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
    
    //MARK: manager
    func get(progressOf name:String)->Float
    {
        if let item = progress[name]
        {
            return get(progressOf:item)
        }
        
        return Float.nan
    }
    
    private func get(progressOf item:AssetProgression)->Float
    {
        return (Float)(Double(item.bytesWritten) / Double(item.bytesExpectedTotal))
    }
    
    internal func get(nameOf url:String)->String
    {
        return String(url.split(separator: "/").last!)
    }
    
    func get(cacheOf url:String)->URL?
    {
        let location = locate(append: get(nameOf: url))
        if FileManager.default.fileExists(atPath: location.path)
        {
            return location
        }
        return nil
    }
    
    func has(cacheOf url:String)->Bool
    {
        let location = locate(append: get(nameOf: url))
        return FileManager.default.fileExists(atPath: location.path)
    }
    
    internal func writeResumeData(_ data:Data, name:String)
    {
        let location = locate(append: "\(name).dl")
        try? data.write(to: location)
    }
    
    internal func readResumeData(name:String)->Data?
    {
        let location = locate(append: "\(name).dl")
        let data = try? Data(contentsOf: location)
        try? FileManager.default.removeItem(at: location)
        return data
    }
    
    func cancel(url:String, resumable:Bool = true)
    {
        let name:String = get(nameOf: url)
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
    
    func fetchAssets(suffix:String = "jpg")->[URL]
    {
        let location = locate()
        let pattern = try? NSRegularExpression(pattern: ".\(suffix)$", options: .caseInsensitive)
        if let files = try? FileManager.default.contentsOfDirectory(at: location, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
        {
            return files.filter
            {
                let range = NSMakeRange(0, $0.path.count)
                if let num = pattern?.numberOfMatches(in: $0.path, options: .reportCompletion, range: range), num > 0
                {
                    return true
                }
                return false
            }
        }
        return []
    }
    
    func removeUserStorage(development:Bool = true)
    {
        let pattern = try? NSRegularExpression(pattern: "x[0-9]{3}.jpg$", options: .caseInsensitive)
        
        let location = locate()
        if let list = try? FileManager.default.contentsOfDirectory(at: location, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
        {
            list.forEach
            {
                if !development
                {
                    try? FileManager.default.removeItem(at: $0)
                }
                else
                {
                    let range = NSMakeRange(0, $0.path.count)
                    if let num = pattern?.numberOfMatches(in: $0.path, options: .reportCompletion, range: range), num > 0
                    {
                        try? FileManager.default.removeItem(at: $0)
                    }
                }
            }
        }
    }
    
    func resume(url:String)
    {
        let name:String = get(nameOf: url)
        if let task = tasks[name]
        {
            task.resume()
        }
    }
    
    func suspend(url:String)
    {
        let name:String = get(nameOf: url)
        if let task = tasks[name]
        {
            task.suspend()
        }
    }
    
    func has(task url:String)->Bool
    {
        let name = get(nameOf: url)
        return tasks[name] != nil
    }
    
    func load(url:String, completion completeHandler:LoadCompleteHandler?, progression progressHandler:LoadProgressHandler? = nil)
    {
        if self.session == nil
        {
            self.session = URLSession(configuration: .background(withIdentifier: AssetManager.identifier),
                                      delegate: self, delegateQueue: .main)
        }
        
        if let url = URL(string: url)
        {
            let name = get(nameOf: url.absoluteString)
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
                print("downloadTask(withResumeData:)", name, data.count)
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

extension AssetManager:URLSessionDownloadDelegate
{
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        if let url = downloadTask.originalRequest?.url
        {
            let name:String = get(nameOf: url.absoluteString)
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
        
        if externalCompletion != nil
        {
            externalCompletion?()
            externalCompletion = nil
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64)
    {
        if let url = downloadTask.originalRequest?.url
        {
            let name:String = get(nameOf: url.absoluteString)
            if let item = progress[name]
            {
                item.bytesWritten = fileOffset
                item.bytesExpectedTotal = expectedTotalBytes
                handlers[name]?.1?(name, get(progressOf: item))
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        if let url = downloadTask.originalRequest?.url
        {
            let name:String = get(nameOf: url.absoluteString)
            if let item = progress[name]
            {
                item.bytesWritten = totalBytesWritten
                item.bytesExpectedTotal = totalBytesExpectedToWrite
                handlers[name]?.1?(name, get(progressOf: item))
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        if let task = task as? URLSessionDownloadTask, let url = task.originalRequest?.url
        {
            let name = get(nameOf: url.path)
            task.cancel(byProducingResumeData:
            {
                if let data = $0
                {
                    print("cancel(byProducingResumeData:)", name, data.count)
                    self.writeResumeData(data, name: name)
                }
            })
        }
        
        if externalCompletion != nil
        {
            externalCompletion?()
            externalCompletion = nil
        }
    }
}


