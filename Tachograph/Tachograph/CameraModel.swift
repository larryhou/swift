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
let LIVE_SERVER = ServerInfo(addr: "10.66.237.223", port: 8800)
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
struct StorageMessage:Codable
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
    case fetchStorage = 0x500/*1280*/, fetchRouteVideos = 0x508/*1288*/, fetchEventVideos = 0x509/*1289*/, fetchImages = 0x50A/*1290*/
    case captureVideo = 0x201/*513*/, captureImage = 0x301/*769*/, notification = 7
}

protocol CameraModelDelegate
{
    func model(command:RemoteCommand, data:Codable)
    func model(assets:[CameraModel.CameraAsset], type:CameraModel.AssetType)
    func modelReady()
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
    
    struct AssetPath
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
    var ready:Bool { return _flags == 0x11 }
    
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
//        _timer?.invalidate()
    }
    
    @objc func heartbeat()
    {
        if _session.connected
        {
            query(type: "app_status")
        }
        else
        {
            if _session.state != .reconnecting
            {
                _session.reconnect()
            }
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
    var images:[CameraAsset] = []
    
    var version:VersionMessage?
    var path:AssetPath?
    
    var token:Int = 1
    private var _flags:Int = 0
    func processMessage(data:Dictionary<String, Any>, bytes:Data) throws
    {
        guard let id = data["msg_id"] as! Int? else { return }
        guard let command = RemoteCommand(rawValue: id) else { return }
        
        let ready = self.ready
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
                _flags |= 0x01
            
            case .fetchStorage:
                let msg = try _decoder.decode(StorageMessage.self, from: bytes)
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
                _flags |= 0x10
                self.path = AssetPath(image: image, event: event, route: route)
                print(self.path!)
            
            case .fetchRouteVideos:
                let msg = try _decoder.decode(AssetsMessage.self, from: bytes)
                parse(assets: msg, target: &routeVideos, assetPath: path!.route)
                delegate?.model(assets: routeVideos, type: .route)
                response = msg
            
            case .fetchEventVideos:
                let msg = try _decoder.decode(AssetsMessage.self, from: bytes)
                parse(assets: msg, target: &eventVideos, assetPath: path!.event)
                delegate?.model(assets: eventVideos, type: .event)
                response = msg
            
            case .fetchImages:
                let msg = try _decoder.decode(AssetsMessage.self, from: bytes)
                parse(assets: msg, target: &images, assetPath: path!.image)
                delegate?.model(assets: images, type: .image)
                response = msg
            
            case .captureImage, .captureVideo:
                let msg = try _decoder.decode(AcknowledgeMessage.self, from: bytes)
                response = msg
            
            case .notification:
                let msg = try _decoder.decode(CaptureNotification.self, from: bytes)
                guard let name = msg.param.split(separator: "/").last else {return}
                if msg.type == "photo_taken"
                {
                    if let asset = parse(name: String(name), assetPath: path!.image)
                    {
                        images.insert(asset, at: 0)
                        delegate?.model(assets: images, type: .image)
                    }
                }
                else if msg.type == "file_new"
                {
                    if let asset = parse(name: String(name), assetPath: path!.route)
                    {
                        routeVideos.insert(asset, at: 0)
                        delegate?.model(assets: routeVideos, type: .route)
                    }
                }
                response = msg
        }
        
        delegate?.model(command: command, data: response)
        print(response)
        
        if self.ready && !ready
        {
            delegate?.modelReady()
        }
    }
    
    func parse(name:String, assetPath:String) -> CameraAsset?
    {
        if let trim = _trim
        {
            let domain = "192.168.42.1"
            let range = NSMakeRange(0, name.count)
            let text = trim.stringByReplacingMatches(in: name, options: [], range: range, withTemplate: "")
            let timestamp = _dateFormatter.date(from: text)
            
            let id:String = String(text.split(separator: "_").last!)
            return CameraAsset(id: id, name: name, url: "http://\(domain)\(assetPath)/\(name)",
                icon: "http://\(domain)\(assetPath)/\(text).thm",
                timestamp: timestamp!)
        }
        
        return nil
    }
    
    func parse(assets:AssetsMessage, target:inout [CameraAsset], assetPath:String)
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
            
            if let asset = parse(name: name, assetPath: assetPath)
            {
                target.append(asset)
            }
        }
        
        target.sort(by: {$0.timestamp > $1.timestamp})
        print(target)
    }
    
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
    
    func fetchStorage()
    {
        let params:[String:Any] = ["token" : self.token, "msg_id" : RemoteCommand.fetchStorage.rawValue]
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
        fetchCameraAssets(command: .fetchImages, position:num, storage: &images)
    }
    
    private func fetchCameraAssets(command:RemoteCommand, position num:Int = 0, storage:inout [CameraAsset])
    {
        let offset = (num == 0 ? storage.count : num) / 20 * 20
        let params:[String:Any] = ["token" : self.token, "msg_id" : command.rawValue, "param" : offset]
        _session.send(data: params)
    }
    
    func captureImage()
    {
        let params:[String:Any] = ["token" : self.token, "msg_id": RemoteCommand.captureImage.rawValue]
        _session.send(data: params)
    }
    
    func captureVideo()
    {
        let params:[String:Any] = ["token" : self.token, "msg_id": RemoteCommand.captureVideo.rawValue]
        _session.send(data: params)
    }
}
