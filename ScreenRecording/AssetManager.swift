//
//  SegmentManager.swift
//  ScreenRecording
//
//  Created by larryhou on 19/01/2018.
//  Copyright © 2018 larryhou. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit
import Photos

let FRAMEWORK_NAME = "ScreenRecording"

class MovieAssetItem:Codable
{
    let id:Int
    let name:String
    let size:Double
    let date:Int
    let path:String
    let snapshot:String
    let duration:Double
    var description:String
    
    init(id:Int, name:String, size:Double, date:Int, path:String, snapshot:String, duration:Double, description:String)
    {
        self.id = id
        self.name = name
        self.size = size
        self.date = date
        self.path = path
        self.snapshot = snapshot
        self.duration = duration
        self.description = description
    }
    
    init(id:Int, path:String, name:String, description:String)
    {
        self.id = id
        self.path = path
        self.snapshot = "\(path).jpg"
        self.name = name
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        self.duration = asset.duration.seconds
        self.description = description
        if let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        {
            self.size = attributes[.size] as! Double
            self.date = Int((attributes[.creationDate] as! Date).timeIntervalSince1970)
        }
        else
        {
            self.size = .nan
            self.date = 0
        }
    }
    
    convenience init(id:Int, location:URL, description:String)
    {
        self.init(id: id, path: location.path, name: location.lastPathComponent, description: description)
    }
    
    func move(to path:String, with id:Int, name:String)->MovieAssetItem
    {
        return MovieAssetItem(id: id, name: name, size: self.size, date: self.date, path: path, snapshot: "\(path).jpg", duration: self.duration, description: self.description)
    }
}

@available(iOS 9.0, *)
class MoviePlayController: AVPlayerViewController
{
    var location:URL?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let press = UILongPressGestureRecognizer(target: self, action: #selector(pressUpdate(_:)))
        press.minimumPressDuration = 1.0
        view.addGestureRecognizer(press)
    }
    
    @objc func pressUpdate(_ sender:UILongPressGestureRecognizer)
    {
        if sender.state == .recognized
        {
            let position = sender.location(ofTouch: 0, in: view)
            showUserOptions(at: position)
        }
    }
    
    func showUserOptions(at position:CGPoint? = nil)
    {
        guard let location = location else {return}
        
        var shareButton:String?, saveButton:String?, cancelButton:String?
        if let tips = Bundle.main.object(forInfoDictionaryKey: FRAMEWORK_NAME) as? Dictionary<String, String>
        {
            shareButton = tips["BUTTON_SHARE"]
            saveButton = tips["BUTTON_SAVE"]
            cancelButton = tips["BUTTON_CANCEL"]
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: saveButton ?? "Save", style: .default, handler:
        { (action) in
            self.saveToAlbum(with: location)
        }))
        alert.addAction(UIAlertAction(title: shareButton ?? "Share", style: .default, handler:
        { (action) in
            self.share(with: location)
        }))
        alert.addAction(UIAlertAction(title: cancelButton ?? "Cancel", style: .cancel, handler: nil))
        if let popover = alert.popoverPresentationController
        {
            let frame = view.frame
            popover.sourceRect = CGRect(x: position?.x ?? frame.width / 2, y: position?.y ?? frame.height / 2, width: 1, height: 1)
            popover.sourceView = view
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    func saveToAlbum(with location:URL)
    {
        AssetManager.shared.saveMovie(with: location.path)
    }
    
    func share(with location:URL)
    {
        AssetManager.shared.shareMovie(with: location, by: self)
    }
}

extension Array where Element == MovieAssetItem
{
    func toJSON()->String?
    {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(self)
        {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func write(to location:URL)
    {
        do
        {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            return try data.write(to: location)
        }
        catch {debug.print(error)}
    }
}

@available(iOS 9.0, *)
@objc public class AssetManager:NSObject
{
    @objc public enum StorageType:Int
    {
        case editor, persistent, all
    }
    
    @objc public static let shared:AssetManager = { return AssetManager() }()
    
    private let PERSISTENT_MOVIE_DIR:URL = {return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Persistent", isDirectory: true)}()
    private let EDITOR_MOVIE_DIR:URL = {return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Editor", isDirectory: true)}()
    private let DATABASE_NAME = "database.json"
    private let background = DispatchQueue(label: "export_movie_clips")
    
    private var userAssets:[MovieAssetItem]
    private var userAssetManager:[Int:MovieAssetItem]
    private var editAssetManager:[Int:MovieAssetItem]
    private var sequence:Int
    
    @objc public let composedMovie:URL
    
    override init()
    {
        userAssets = []
        userAssetManager = [:]
        editAssetManager = [:]
        sequence = 1
        
        do
        {
            try FileManager.default.createDirectory(at: PERSISTENT_MOVIE_DIR, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: EDITOR_MOVIE_DIR, withIntermediateDirectories: true, attributes: nil)
        }
        catch {debug.print(error)}
        
        self.composedMovie = EDITOR_MOVIE_DIR.appendingPathComponent("compose.mp4")
        super.init()
        
        reload()
    }
    
    private func reload()
    {
        var cleaner:[String:String] = [:]
        
        do
        {
            let data = try Data(contentsOf: PERSISTENT_MOVIE_DIR.appendingPathComponent(DATABASE_NAME))
            let decoder = JSONDecoder()
            userAssets = try decoder.decode([MovieAssetItem].self, from: data)
            userAssets.sort(by: {$0.id < $1.id})
            for item in userAssets
            {
                if !FileManager.default.fileExists(atPath: item.path) {continue}
                userAssetManager[item.id] = item
                sequence = max(sequence, item.id)
                
                cleaner[item.name] = item.path
                let snapshot = String(item.snapshot.split(separator: "/").last!)
                cleaner[snapshot] = item.snapshot
            }
            
            sequence += 1
        }
        catch{debug.print(error)}
        
        do
        {
            let movies = try FileManager.default.contentsOfDirectory(at: PERSISTENT_MOVIE_DIR,
                                                                     includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
                                                                     options: .skipsSubdirectoryDescendants)
            for location in movies
            {
                if location.pathExtension == "json"{continue}
                if cleaner[location.lastPathComponent] == nil
                {
                    try FileManager.default.removeItem(at: location)
                }
            }
        }
        catch {debug.print(error)}
    }
    
    @objc public func playMovie(with url:URL)
    {
        debug.print("[AssetManager]", "playMovie(with:)", url.path, FileManager.default.fileExists(atPath: url.path))
        let player = AVPlayer(url: url)
        let reviewController = MoviePlayController()
        reviewController.player = player
        reviewController.location = url
        topController?.present(reviewController, animated: true, completion: nil)
        player.play()
    }
    
    @objc public func shareMovie(with url:URL, by controller:UIViewController? = nil)
    {
        let share = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let presentController = controller ?? topController
        {
            if let popover = share.popoverPresentationController
            {
                let frame = presentController.view.frame
                popover.sourceView = presentController.view
                popover.sourceRect = CGRect(x: 0, y: frame.height / 2, width: 1, height: 1)
            }
            presentController.present(share, animated: true, completion: nil)
        }
    }
    
    @objc public func cleanupStorage(type:StorageType = .editor)
    {
        do
        {
            switch type
            {
                case .editor:
                    try FileManager.default.removeItem(at: EDITOR_MOVIE_DIR)
                case .persistent:
                    try FileManager.default.removeItem(at: PERSISTENT_MOVIE_DIR)
                case .all:
                    try FileManager.default.removeItem(at: PERSISTENT_MOVIE_DIR)
                    try FileManager.default.removeItem(at: EDITOR_MOVIE_DIR)
            }
            
            try FileManager.default.createDirectory(at: PERSISTENT_MOVIE_DIR, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: EDITOR_MOVIE_DIR, withIntermediateDirectories: true, attributes: nil)
        }
        catch {}
    }
    
    private var exportInstuctions:[ExportSessionInstruction]!
    func processMovieSessions(instructions:[ExportSessionInstruction], completion:(()->Void)? = nil)
    {
        debug.print("[AssetManager] processMovieSessions(instructions:completion:)")
        exportInstuctions = instructions
        position = 0
        
        exportMovieSession(instructions, at: 0, completion: completion)
    }
    
    @objc public func cancelExportSessions()
    {
        if let session = currentSession, session.status == .exporting
        {
            session.cancelExport()
        }
        
        exportInstuctions?.removeAll()
    }
    
    @objc public var progress:Float
    {
        guard let instructions = exportInstuctions, instructions.count > 0 && position >= 0 else {return .nan}
        
        var value = Float(position) / Float(instructions.count)
        if currentSession.status == .exporting
        {
            value += currentSession.progress / Float(instructions.count)
        }
        else
        {
            value += 1 / Float(instructions.count)
        }
        
        return value
    }
    
    func attributes(of filepath:String)->String
    {
        if let attributes = try? FileManager.default.attributesOfItem(atPath: filepath)
        {
            var jsonObject:[String:String] = [:]
            for (key, value) in attributes
            {
                jsonObject[key.rawValue] = String(describing: value)
            }
            if let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            {
                return String(data: data, encoding: .utf8)!
            }
        }
        
        return "nil"
    }
    
    private var currentSession:AVAssetExportSession!, position:Int = -1
    private func exportMovieSession(_ instructions:[ExportSessionInstruction], at index:Int = 0, completion:(()->Void)? = nil)
    {
        if index < instructions.count
        {
            debug.print("[AssetManager]", "exportMovieSession(_:at#\(index):completion:) call")
            
            let timestamp = Date()
            
            position = index
            currentSession = instructions[index].session
            currentSession.shouldOptimizeForNetworkUse = true
            currentSession.exportAsynchronously
            {
                let elapse = Date().timeIntervalSince(timestamp)
                debug.print("[AssetManager]", "AVAssetExportSession.exportAsynchronously(completionHandler:)","\(index + 1)/\(instructions.count)",
                    self.currentSession.outputURL!.path,
                    self.currentSession.status, "elapse:\(elapse)s", self.currentSession.error ?? "success",
                    self.attributes(of: self.currentSession.outputURL!.path))
                if let location = self.currentSession.outputURL, FileManager.default.fileExists(atPath: location.path)
                {
                    self.exportMovieSnapshot(for: location)
                    
                    let movieItem = MovieAssetItem(id: index, location: location, description: instructions[index].comment)
                    self.editAssetManager[movieItem.id] = movieItem
                }
                self.exportMovieSession(instructions, at: index + 1, completion: completion)
            }
        }
        else
        {
            // save to database
            var list:[MovieAssetItem] = []
            for (_, item) in editAssetManager
            {
                list.append(item)
            }
            list.write(to: EDITOR_MOVIE_DIR.appendingPathComponent(DATABASE_NAME))
            debug.print("[AssetManager]", "exportMovieSession(_:at:completion:) finish sessions")
            completion?()
        }
    }
    
    private func exportMovieSnapshot(for location:URL)
    {
        do
        {
            let asset = AVAsset(url: location)
            
            let duration = asset.duration
            guard !duration.seconds.isNaN && duration.seconds > 0 else {return}
            
            let reader = try AVAssetReader(asset: asset)
            let output = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: .video)[0], outputSettings: [kCVPixelBufferPixelFormatTypeKey:kCVPixelFormatType_32BGRA] as [String:Any])
            output.alwaysCopiesSampleData = false
            reader.add(output)
            reader.timeRange = CMTimeRange(start: CMTime(value: duration.value / 2, timescale: duration.timescale),
                                           duration: CMTime(seconds: 1, preferredTimescale: duration.timescale))
            reader.startReading()
            
            var index = 0
            while index < 20
            {
                index += 1
                if let sample = output.copyNextSampleBuffer(), CMSampleBufferGetNumSamples(sample) == 1
                {
                    if let buffer = CMSampleBufferGetImageBuffer(sample)
                    {
                        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
                        
                        let aspect = CGSize(width: 4, height: 3)
                        let scale:CGFloat = 300 / aspect.width
                        
                        let snapshot = CIImage(cvImageBuffer: buffer)
                        var image = UIImage(ciImage: snapshot)
                        
                        let size = image.size
                        let width = size.height / aspect.height * aspect.width
                        let height = size.width / aspect.width * aspect.height
                        
                        let region:CGRect
                        if size.width > width
                        {
                            region = CGRect(x: (size.width - width) / 2, y: 0, width: width, height: size.height)
                        }
                        else
                        {
                            region = CGRect(x: 0, y: (size.height - height) / 2, width: size.width, height: height)
                        }
                        
                        image = UIImage(ciImage: snapshot.cropped(to: region))
                        
                        let canvas = CGSize(width: aspect.width * scale, height: aspect.height * scale)
                        
                        UIGraphicsBeginImageContext(canvas)
                        defer { UIGraphicsEndImageContext() }
                        image.draw(in: CGRect(origin: CGPoint.zero, size: canvas))
                        let cover = UIGraphicsGetImageFromCurrentImageContext()!
                        
                        if let binary = UIImageJPEGRepresentation(cover, 0.75)
                        {
                            let destination = location.appendingPathExtension("jpg")
                            try binary.write(to: destination)
                            debug.print("[AssetManager]", "exportMovieSnapshot(for:)", destination.path)
                        }
                        break
                    }
                }
            }
            reader.cancelReading()
        }
        catch {debug.print(error)}
        
    }
    
    @objc public func change(description:String, for movieID:Int)
    {
        if let item = userAssetManager[movieID]
        {
            item.description = description
            databaseUpdate()
        }
    }
    
    @discardableResult
    @objc public func removeUserMovie(id:Int)->Bool
    {
        for index in 0..<userAssets.count
        {
            let item = userAssets[index]
            if item.id == id
            {
                return removeUserMovie(item: item, at: index) != nil
            }
        }
        return false
    }
    
    private func removeUserMovie(item:MovieAssetItem, at index:Int)->MovieAssetItem?
    {
        if FileManager.default.fileExists(atPath: item.path)
        {
            do
            {
                try FileManager.default.removeItem(atPath: item.path)
                userAssetManager.removeValue(forKey: item.id)
                userAssets.remove(at: index)
                databaseUpdate()
                return item
            }
            catch {debug.print(error)}
        }
        
        return nil
    }
    
    private func getPersistentMovieURL()->URL
    {
        return PERSISTENT_MOVIE_DIR.appendingPathComponent("REC_\(format(index: sequence)).mp4")
    }
    
    func getEditorMovieURL(with index:Int)->URL
    {
        return EDITOR_MOVIE_DIR.appendingPathComponent("TMP_\(format(index: index)).mp4")
    }
    
    @objc public func saveMovie(with path:String)
    {
        requestAlbumAuthorization
        {
            UISaveVideoAtPathToSavedPhotosAlbum(path, self, #selector(self.video(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc public func saveImage(with path:String)
    {
        requestAlbumAuthorization
        {
            if let image = UIImage(contentsOfFile: path)
            {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    
    @objc private func image(_ image:UIImage, didFinishSavingWithError error:NSError?, contextInfo:UnsafeRawPointer)
    {
        var successMessage:String?
        var failureMessage:String?
        var confirmMessage:String?
        if let tips = Bundle.main.object(forInfoDictionaryKey: FRAMEWORK_NAME) as? Dictionary<String, String>
        {
            successMessage = tips["TIPS_SAVE_IMAGE_SUCCESS"]
            failureMessage = tips["TIPS_SAVE_IMAGE_FAILURE"]
            confirmMessage = tips["BUTTON_CONFIRM"]
        }
        
        let alert = UIAlertController(title: error == nil ? (successMessage ?? "success") : (failureMessage ?? "failure"), message: error?.debugDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: confirmMessage ?? "OK", style: .cancel, handler: nil))
        topController?.present(alert, animated: true, completion: nil)
    }
    
    func requestAlbumAuthorization(completion:@escaping ()->Void)
    {
        if PHPhotoLibrary.authorizationStatus() != .authorized
        {
            PHPhotoLibrary.requestAuthorization
            { (status) in
                if status == .authorized {completion()}
            }
        }
        else
        {
            completion()
        }
    }
    
    @objc func video(_ videoPath:String, didFinishSavingWithError error:NSError?, contextInfo context:Any?)
    {
        var successMessage:String?
        var failureMessage:String?
        var confirmMessage:String?
        if let tips = Bundle.main.object(forInfoDictionaryKey: FRAMEWORK_NAME) as? Dictionary<String, String>
        {
            successMessage = tips["TIPS_SAVE_VIDEO_SUCCESS"]
            failureMessage = tips["TIPS_SAVE_VIDEO_FAILURE"]
            confirmMessage = tips["BUTTON_CONFIRM"]
        }
        
        let alert = UIAlertController(title: error == nil ? (successMessage ?? "success") : (failureMessage ?? "failure"), message: error?.debugDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: confirmMessage ?? "OK", style: .cancel, handler: nil))
        topController?.present(alert, animated: true, completion: nil)
    }
    
    var topController:UIViewController?
    {
        var viewController:UIViewController? = UIApplication.shared.keyWindow?.rootViewController
        while let agentController = viewController?.presentedViewController
        {
            viewController = agentController
        }
        return viewController
    }
    
    
    @discardableResult
    @objc public func keepEditMovie(id:Int)->Bool
    {
        guard let data = editAssetManager[id] else
        {
            debug.print("[AssetManager]", "saveUserMovie(id:\(id)", "not found")
            return false
        }
        
        let source = URL(fileURLWithPath: data.path)
        let destination = getPersistentMovieURL()
        
        do
        {
            // save video snapshot
            let srcSnapshot = source.appendingPathExtension("jpg")
            let dstSnapshot = destination.appendingPathExtension("jpg")
            try? FileManager.default.removeItem(at: dstSnapshot)
            try FileManager.default.moveItem(at: srcSnapshot, to: dstSnapshot)
            try FileManager.default.createSymbolicLink(at: srcSnapshot, withDestinationURL: dstSnapshot)
            
            // save movie
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: source, to: destination)
            try FileManager.default.createSymbolicLink(at: source, withDestinationURL: destination)
            
            let item = data.move(to: destination.path, with: sequence, name: destination.lastPathComponent)
            userAssetManager[item.id] = item
            userAssets.append(item)
            databaseUpdate()
            sequence += 1
            debug.print("[AssetManager]", "<MOVE_TO>", "\(source.path) => \(destination.path)")
            return true
            
        }
        catch {debug.print(error)}
        
        return false
    }
    
    private func databaseUpdate()
    {
        var list:[MovieAssetItem] = []
        for (_, item) in userAssetManager
        {
            list.append(item)
        }
        
        list.write(to: PERSISTENT_MOVIE_DIR.appendingPathComponent(DATABASE_NAME))
    }
    
    @objc public func real(of path:String)->String?
    {
        do
        {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let type = attributes[.type] as? FileAttributeType, type == FileAttributeType.typeSymbolicLink
            {
                return try FileManager.default.destinationOfSymbolicLink(atPath: path)
            }
            return path
        }
        catch {debug.print(error)}
        
        return nil
    }
    
    private func format(index:Int, length:Int = 3)->String
    {
        return String(format: "%0\(length)d", index)
    }
    
    @objc public var availableSpace:Double
    {
        let document = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do
        {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: document.path)
            if let space = attributes[.systemFreeSize] as? Double
            {
                return space
            }
        }
        catch {debug.print(error)}
        
        return -1
    }
    
    @objc public var recordingAvailable:Bool
    {
        let space = self.availableSpace / 1024 / 1024 / 1024 // >= 1GB
        return space >= 1.0
    }
    
    @objc public var editJSON:String?
    {
        var list:[MovieAssetItem] = []
        for (_, item) in editAssetManager
        {
            list.append(item)
        }
        return list.toJSON()
    }
    
    @objc public var userJSON:String?
    {
        return userAssets.toJSON()
    }
}
