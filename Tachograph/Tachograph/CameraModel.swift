//
//  SessionModel.swift
//  Tachograph
//
//  Created by larryhou on 1/7/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
struct ServerInfo
{
    let addr:String
    let port:UInt32
}

#if NATIVE_DEBUG
let LIVE_SERVER = ServerInfo(addr: "10.66.195.136", port: 8800)
#else
let LIVE_SERVER = ServerInfo(addr: "192.168.42.1", port: 7878)
#endif

struct AcknowledgeMessage:Codable
{
    let rval, msg_id:Int
}

//{ "rval": 0, "msg_id": 1, "type": "date_time", "param": "2017-06-29 19:25:12" }
struct QueryMessage:Codable
{
    let rval, msg_id:Int
    let type, param:String
}

struct TokenMessage:Codable
{
    let rval, msg_id, param:Int
}

//{ "rval": 0, "msg_id": 1290, "totalFileNum": 37, "param": 0, "listing": [
struct AssetsMessage:Codable
{
    struct Asset:Codable
    {
        let name:String
    }
    
    let rval, msg_id, totalFileNum, param:Int
    let listing:[Asset]
}
//{ "rval": 0, "msg_id": 1280, "listing": [ { "path": "\/mnt\/mmc01\/DCIM", "type": "nor_video" }, { "path": "\/mnt\/mmc01\/EVENT", "type": "event_video" }, { "path": "\/mnt\/mmc01\/PICTURE", "type": "cap_img" } ] }
struct AssetIndexMessage:Codable
{
    struct Folder:Codable
    {
        let path, type:String
    }
    
    let rval, msg_id:Int
    let listing:[Folder]
}

//{ "rval": 0, "msg_id": 11, "camera_type": "AE-CS2016-HZ2", "firm_ver": "V1.1.0", "firm_date": "build 161031", "param_version": "V1.3.0", "serial_num": "655136915", "verify_code": "JXYSNT" }
struct VersionMessage:Codable
{
    let rval, msg_id:Int
    let camera_type, firm_ver, firm_date, param_version, serial_num, verify_code:String
}

//{ "msg_id": 7, "type": "photo_taken", "param": "\/mnt\/mmc01\/PICTURE\/ch1_20170701_2022_0053.jpg" }
struct CaptureNotification:Codable
{
    let msg_id:Int
    let type, param:String
}

enum RemoteCommand:Int
{
    case query = 1, fetchVersion = 11, fetchToken = 0x101/*257*/
    case fetchAssetIndex = 0x500/*1280*/, fetchRouteVideos = 0x508/*1288*/, fetchEventVideos = 0x509/*1289*/, fetchImages = 0x50A/*1290*/
    case captureVideo = 0x201/*513*/, captureImage = 0x301/*769*/, notification = 7
}

protocol CameraModelDelegate:NSObjectProtocol
{
    func model(assets:[CameraModel.CameraAsset], type:CameraModel.AssetType)
    func model(update:CameraModel.CameraAsset, type:CameraModel.AssetType)
}

class CameraModel:TCPSessionDelegate
{
    struct CameraAsset
    {
        let id, name, url, icon:String
        let timestamp:Date
    }
    
    enum AssetType
    {
        case image, event, route
    }
    
    struct AssetIndex
    {
        let image, event, route:String
    }
    
    static private var _model:CameraModel?
    static var shared:CameraModel
    {
        if _model == nil
        {
            _model = CameraModel()
        }
        return _model!
    }
    
    var delegate:CameraModelDelegate?
    private(set) var ready:Bool = false
    
    private var _session:TCPSession
    private var _decoder:JSONDecoder
    private var _dateFormatter:DateFormatter
    private var _trim:NSRegularExpression?
    
    private var _timer:Timer?
    
    init()
    {
        _session = TCPSession()
        _session.connect(address: LIVE_SERVER.addr, port: LIVE_SERVER.port)
        
        _decoder = JSONDecoder()
        
        _dateFormatter = DateFormatter()
        _dateFormatter.dateFormat = "'ch1_'yyyyMMdd_HHmm_SSSS" // ch1_20170628_2004_0042
        
        _trim = try? NSRegularExpression(pattern: "\\.[^\\.]+$", options: .caseInsensitive)
        
        _session.delegate = self
        _timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(heartbeat), userInfo: nil, repeats: true)
        #if NATIVE_DEBUG
        _timer?.invalidate()
        #endif
    }
    
    @objc func heartbeat()
    {
        if _session.connected
        {
            query(type: "app_status")
        }
        else
        {
            if _session.state != .connecting
            {
                _session.clear()
                _session.reconnect()
            }
        }
    }
    
    func tcpUpdate(session: TCPSession)
    {
        if _taskQueue.count > 0 && ready
        {
            _session.send(data: _taskQueue.remove(at: 0))
        }
    }
    
    func tcp(session: TCPSession, state: TCPSessionState)
    {
        if state == .connected
        {
            fetchToken()
        }
        else if state == .closed
        {
            ready = false
        }
    }
    
    func tcp(session: TCPSession, data: Data)
    {
        do
        {
            if data.count == 0 { return }
            try data.withUnsafeBytes({ (pointer:UnsafePointer<UInt8>) in
                var position = pointer, start = pointer, found = false, depth = 0
                for _ in 0..<data.count
                {
                    if position.pointee == 0x5b || position.pointee == 0x7b
                    {
                        found = true
                        depth += 1
                    }
                    else
                    if position.pointee == 0x5d || position.pointee == 0x7d
                    {
                        depth -= 1
                    }
                    
                    position = position.advanced(by: 1)
                    if found && depth == 0
                    {
                        let message = Data(bytes:start, count:start.distance(to: position))
                        if let jsonObject = try JSONSerialization.jsonObject(with: message, options: .allowFragments) as? Dictionary<String, Any>
                        {
                            try processMessage(data: jsonObject, bytes: message)
                        }
                        start = position
                        found = false
                    }
                }
            })
        }
        catch
        {
            print(String(data:data, encoding:.utf8)!)
            print(error)
        }
    }
    
    var eventVideos:[CameraAsset] = []
    var routeVideos:[CameraAsset] = []
    var tokenImages:[CameraAsset] = []
    
    var version:VersionMessage?
    var assetIndex:AssetIndex!
    
    var token:Int = 1
    func processMessage(data:Dictionary<String, Any>, bytes:Data) throws
    {
        guard let id = data["msg_id"] as! Int? else { return }
        guard let command = RemoteCommand(rawValue: id) else { return }
        
        var response:Codable
        switch command
        {
            case .query:
                let msg = try _decoder.decode(QueryMessage.self, from: bytes)
                response = msg
            
            case .fetchVersion:
                self.version = try _decoder.decode(VersionMessage.self, from: bytes)
                response = self.version!
            
            case .fetchToken:
                let msg = try _decoder.decode(TokenMessage.self, from: bytes)
                self.token = msg.param
                response = msg
                preload()
            
            case .fetchAssetIndex:
                let msg = try _decoder.decode(AssetIndexMessage.self, from: bytes)
                var route = "", event = "", image = ""
                for item in msg.listing
                {
                    let location = "/SMCAR/DOWNLOAD\(item.path)"
                    switch item.type
                    {
                        case "nor_video":
                            route = location
                        case "event_video":
                            event = location
                        case "cap_img":
                            image = location
                        default:break
                    }
                }
                response = msg
                self.assetIndex = AssetIndex(image: image, event: event, route: route)
                print(self.assetIndex)
            
            case .fetchRouteVideos:
                let msg = try _decoder.decode(AssetsMessage.self, from: bytes)
                parse(assets: msg, target: &routeVideos, type: .route)
                delegate?.model(assets: routeVideos, type: .route)
                response = msg
            
            case .fetchEventVideos:
                let msg = try _decoder.decode(AssetsMessage.self, from: bytes)
                parse(assets: msg, target: &eventVideos, type: .event)
                delegate?.model(assets: eventVideos, type: .event)
                response = msg
            
            case .fetchImages:
                let msg = try _decoder.decode(AssetsMessage.self, from: bytes)
                parse(assets: msg, target: &tokenImages, type: .image)
                delegate?.model(assets: tokenImages, type: .image)
                response = msg
            
            case .captureImage, .captureVideo:
                let msg = try _decoder.decode(AcknowledgeMessage.self, from: bytes)
                response = msg
            
            case .notification:
                let msg = try _decoder.decode(CaptureNotification.self, from: bytes)
                guard let name = msg.param.split(separator: "/").last else {return}
                if msg.type == "photo_taken"
                {
                    if let asset = parse(name: String(name), type: .image)
                    {
                        tokenImages.insert(asset, at: 0)
                        delegate?.model(update: asset, type: .image)
                    }
                }
                else if msg.type == "file_new"
                {
                    if msg.param.contains("/EVENT/")
                    {
                        if let asset = parse(name: String(name), type: .event)
                        {
                            eventVideos.insert(asset, at: 0)
                            delegate?.model(update: asset, type: .event)
                        }
                    }
                    else
                    {
                        if let asset = parse(name: String(name), type: .route)
                        {
                            routeVideos.insert(asset, at: 0)
                            delegate?.model(update: asset, type: .route)
                        }
                    }
                    
                }
                response = msg
        }
        
        print(response)
        if command == .fetchAssetIndex
        {
            ready = true
        }
    }
    
    private var _countAsset:[AssetType:Int] = [:]
    func parse(name:String, type:AssetType) -> CameraAsset?
    {
        guard let trim = _trim else {return nil}
        
        let range = NSMakeRange(0, name.count)
        let text = trim.stringByReplacingMatches(in: name, options: [], range: range, withTemplate: "")
        let timestamp = _dateFormatter.date(from: text)!
        let id:String = String(text.split(separator: "_").last!)
        
        #if NATIVE_DEBUG
        let index = String(format: "%03d", _countAsset[type] ?? 0)
        let server = "http://\(LIVE_SERVER.addr):8080/camera"
        let sample = "\(server)/videos/sample.mp4"
        let asset:CameraAsset
        switch type
        {
            case .event, .route:
                let url = "\(server)/videos/\(index).thm"
                asset = CameraAsset(id: id, name: "sample.mp4", url: sample, icon: url, timestamp: timestamp)
            case .image:
                asset = CameraAsset(id: id, name: "sample.mp4",
                                    url: "\(server)/images/x\(index).jpg",
                                    icon: "\(server)/images/x\(index).thm",
                                    timestamp: timestamp)
        }
        return asset
        #else
        let subpath:String
        switch type
        {
            case .event:subpath = assetIndex.event
            case .image:subpath = assetIndex.image
            case .route:subpath = assetIndex.route
        }
        let server = "http://\(LIVE_SERVER.addr)/\(subpath)"
        return CameraAsset(id: id, name: name, url: "\(server)/\(name)",
            icon: "\(server)/\(text).thm",
            timestamp: timestamp)
        #endif
    }
    
    func parse(assets:AssetsMessage, target:inout [CameraAsset], type:AssetType)
    {
        var dict:[String:CameraAsset] = [:]
        for item in target
        {
            dict[item.name] = item
        }
        
        for item in assets.listing
        {
            let name = item.name
            if dict[name] != nil
            {
                continue
            }
            
            if let asset = parse(name: name, type: type)
            {
                target.append(asset)
                _countAsset[type] = target.count
            }
        }
        
        target.sort(by: {$0.timestamp > $1.timestamp})
        print(target)
    }
    
    private func preload()
    {
        fetchVersion()
        query(type: "app_status")
        query(type: "date_time")
        fetchAssetIndex()
    }
    
    private var _taskQueue:[[String:Any]] = []
    func query(type:String = "date_time")
    {
        let params:[String:Any] = ["token" : self.token, "msg_id" : RemoteCommand.query.rawValue, "type" : type]
        _session.send(data: params)
    }
    
    func fetchToken()
    {
        let params:[String:Any] = ["token" : 0, "msg_id" : RemoteCommand.fetchToken.rawValue]
        _session.send(data: params)
    }
    
    func fetchVersion()
    {
        let params:[String:Any] = ["token" : self.token, "msg_id" : RemoteCommand.fetchVersion.rawValue]
        _session.send(data: params)
    }
    
    func fetchAssetIndex()
    {
        let params:[String:Any] = ["token" : self.token, "msg_id" : RemoteCommand.fetchAssetIndex.rawValue]
        _session.send(data: params)
    }
    
    func fetchEventVideos(position num:Int = 0)
    {
        fetchCameraAssets(command: .fetchEventVideos, position:num, storage: &eventVideos)
    }
    
    func fetchRouteVideos(position num:Int = 0)
    {
        fetchCameraAssets(command: .fetchRouteVideos, position:num, storage: &routeVideos)
    }
    
    func fetchImages(position num:Int = 0)
    {
        fetchCameraAssets(command: .fetchImages, position:num, storage: &tokenImages)
    }
    
    private func fetchCameraAssets(command:RemoteCommand, position num:Int = 0, storage:inout [CameraAsset])
    {
        let offset = (num == 0 ? storage.count : num) / 20 * 20
        let params:[String:Any] = ["token" : self.token, "msg_id" : command.rawValue, "param" : offset]
        _taskQueue.append(params)
    }
    
    func captureImage()
    {
        let params:[String:Any] = ["token" : self.token, "msg_id": RemoteCommand.captureImage.rawValue]
        _taskQueue.append(params)
    }
    
    func captureVideo()
    {
        let params:[String:Any] = ["token" : self.token, "msg_id": RemoteCommand.captureVideo.rawValue]
        _taskQueue.append(params)
    }
}
