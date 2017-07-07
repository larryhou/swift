//
//  ResourceLoader.swift
//  Tachograph
//
//  Created by larryhou on 7/7/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation

protocol AssetManagerDelegate
{
    func assetUpdate(url:String, name:String, location:URL)
}

class AssetManager:NSObject, URLSessionDownloadDelegate
{
    class UnfinishedTask:Codable
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
    
    private let queue = DispatchQueue(label: "assets_loading_queue")
    private var loadingQueue:[String:UnfinishedTask] = [:]
    private var dict:[String:URLSessionDownloadTask] = [:]
    
    var delegate:AssetManagerDelegate?
    
    private func getUserWorkspace()->URL
    {
        return try! FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    //MARK: session delegate
    @available(iOS 7.0, *)
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        if let url = downloadTask.originalRequest?.url
        {
            let name:String = get(url: url.absoluteString)
            loadingQueue.removeValue(forKey: name)
            dict.removeValue(forKey: name)
            
            var destination = getUserWorkspace()
            destination.appendPathComponent(name)
            
            do
            {
                try FileManager.default.moveItem(at: location, to: destination)
                delegate?.assetUpdate(url: url.absoluteString, name: name, location: destination)
            }
            catch
            {
                delegate?.assetUpdate(url: url.absoluteString, name: name, location: location)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64)
    {
        if let url = downloadTask.originalRequest?.url
        {
            let name:String = get(url: url.absoluteString)
            if let item = loadingQueue[name]
            {
                item.bytesWritten = fileOffset
                item.bytesExpectedTotal = expectedTotalBytes
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        if let url = downloadTask.originalRequest?.url
        {
            let name:String = get(url: url.absoluteString)
            if let item = loadingQueue[name]
            {
                item.bytesWritten = totalBytesWritten
                item.bytesExpectedTotal = totalBytesExpectedToWrite
            }
        }
    }
    
    //MARK: manager
    private func get(url:String)->String
    {
        return String(url.split(separator: "/").last!)
    }
    
    func get(url:String)->Data?
    {
        var location = getUserWorkspace()
        location.appendPathComponent(get(url: url))
        return try? Data(contentsOf: location)
    }
    
    private func writeResumeData(_ data:Data, name:String)
    {
        var location = getUserWorkspace()
        location.appendPathComponent("\(name).dl")
        
        try? data.write(to: location)
    }
    
    private func readResumeData(name:String, deleteAfterReading:Bool = true)->Data?
    {
        var location = getUserWorkspace()
        location.appendPathComponent("\(name).dl")
        
        let data = try? Data(contentsOf: location)
        if deleteAfterReading
        {
            try? FileManager.default.removeItem(at: location)
        }
        return data
    }
    
    func cancel(url:String)
    {
        let name:String = get(url: url)
        if let task = dict[name]
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
        let name:String = get(url: url)
        if let task = dict[name]
        {
            task.resume()
        }
    }
    
    func suspend(url:String)
    {
        let name:String = get(url: url)
        if let task = dict[name]
        {
            task.suspend()
        }
    }
    
    func load(url:String)
    {
        if let url = URL(string: url)
        {
            let item = UnfinishedTask(url: url.absoluteString)
            loadingQueue[item.name] = item
            
            let task:URLSessionDownloadTask
            if let data = readResumeData(name: item.name)
            {
                task = URLSession.shared.downloadTask(withResumeData: data)
            }
            else
            {
                task = URLSession.shared.downloadTask(with: url)
            }
            dict[item.name] = task
            task.resume()
        }
    }
}
