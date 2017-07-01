//
//  SessionModel.swift
//  Tachograph
//
//  Created by larryhou on 1/7/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation

protocol RemoteMessage
{
    var rval:Int { get }
    var msg_id:Int { get }
}

//{ "rval": 0, "msg_id": 1, "type": "date_time", "param": "2017-06-29 19:25:12" }
struct CommonMessage:Codable, RemoteMessage
{
    let rval, msg_id:Int
    let type, param:String
}

struct TokenMessage:Codable, RemoteMessage
{
    let rval, msg_id, param:Int
}

//{ "rval": 0, "msg_id": 1290, "totalFileNum": 37, "param": 0, "listing": [
struct AssetsMessage:Codable, RemoteMessage
{
    struct Asset:Codable
    {
        let name:String
    }
    
    let rval, msg_id, totalFileNum, param:Int
    let listing:[Asset]
}
//{ "rval": 0, "msg_id": 1280, "listing": [ { "path": "\/mnt\/mmc01\/DCIM", "type": "nor_video" }, { "path": "\/mnt\/mmc01\/EVENT", "type": "event_video" }, { "path": "\/mnt\/mmc01\/PICTURE", "type": "cap_img" } ] }
struct HierarchyMessage:Codable, RemoteMessage
{
    struct Folder:Codable
    {
        let path, type:String
    }
    
    let rval, msg_id:Int
    let listing:[Folder]
}

//{ "rval": 0, "msg_id": 11, "camera_type": "AE-CS2016-HZ2", "firm_ver": "V1.1.0", "firm_date": "build 161031", "param_version": "V1.3.0", "serial_num": "655136915", "verify_code": "JXYSNT" }
struct VersionMessage:Codable,RemoteMessage
{
    let rval, msg_id:Int
    let camera_type, firm_ver, firm_date, param_version, serial_num, verify_code:String
}

//LOOKUP = 1
//SYSTEM = 11
//FETCH_TOKEN = 257
//FETCH_FOLDERS = 1280
//FETCH_ROUTE_VIDEO_LIST = 1288
//FETCH_EVENT_VIDEO_LIST = 1289
//FETCH_IMAGE_LIST = 1290
//CAPTURE_IMAGE = 769
//NOTIFY_IMAGE = 7

enum RemoteCommand:Int
{
    case lookup = 1, fetchVersion = 11, fetchToken = 257
    case fetchHierarchy = 1280, fetchRouteVideos = 1288, fetchEventVideos = 1289, fetchImages = 1290
    case capture = 7
}

protocol CameraModelDelegate
{
    func model(command:RemoteCommand, data:RemoteMessage)
    func model(ready:Bool)
}

class CameraModel:TCPSessionDelegate
{
    struct CameraAsset
    {
        let name, url, icon:String
        let timestamp:Date
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
    
    init()
    {
        _session = TCPSession()
        _session.connect(address: "172.20.10.3", port: 8800)
        
        _decoder = JSONDecoder()
        
        _dateFormatter = DateFormatter()
        _dateFormatter.dateFormat = "'ch1_'yyyyMMdd_HHmm_ssSS" // ch1_20170628_2004_0042
        
        _trim = try? NSRegularExpression(pattern: "\\.[^\\.]+$", options: .caseInsensitive)
        
        _session.delegate = self
    }
    
    func tcp(session: TCPSession, data: Data)
    {
        do
        {
            if let msg = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any>
            {
                try processMessage(data: msg, bytes: data)
            }
        }
        catch
        {
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
        
//        print(String(data:bytes, encoding:.utf8)!)
        let ready = self.ready
        var response:RemoteMessage?
        switch command
        {
            case .lookup:
                let msg = try _decoder.decode(CommonMessage.self, from: bytes)
                response = msg
                print(msg)
            
            case .fetchVersion:
                self.version = try _decoder.decode(VersionMessage.self, from: bytes)
                response = self.version
            
            case .fetchToken:
                let msg = try _decoder.decode(TokenMessage.self, from: bytes)
                self.token = msg.param
                response = msg
                _flags |= 0x01
                print(msg)
            
            case .fetchHierarchy:
                let msg = try _decoder.decode(HierarchyMessage.self, from: bytes)
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
                response = msg
            
            case .fetchEventVideos:
                let msg = try _decoder.decode(AssetsMessage.self, from: bytes)
                parse(assets: msg, target: &eventVideos, assetPath: path!.event)
                response = msg
            
            case .fetchImages:
                let msg = try _decoder.decode(AssetsMessage.self, from: bytes)
                parse(assets: msg, target: &images, assetPath: path!.image)
                response = msg
            
            default:
                break
        }
        
        if let rsp = response
        {
            delegate?.model(command: command, data: rsp)
        }
        
        if self.ready && !ready
        {
            delegate?.model(ready: true)
        }
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
            
            if let trim = _trim
            {
                let range = NSMakeRange(0, name.count)
                let text = trim.stringByReplacingMatches(in: name, options: [], range: range, withTemplate: "")
                let timestamp = _dateFormatter.date(from: text)
                let asset = CameraAsset(name: name, url: "http://192.168.42.1\(assetPath)/\(item.name)",
                    icon: "http://192.168.42.1\(assetPath)/\(text).thm",
                    timestamp: timestamp!)
                target.append(asset)
            }
        }
        
        target.sort(by: {$0.timestamp > $1.timestamp})
        print(target)
    }
    
    func lookup(type:String = "date_time")
    {
//        {"token" : 1, "msg_id" : 1, "type":"date_time"}
        let params:[String:Any] = ["token" : self.token, "msg_id" : RemoteCommand.lookup.rawValue, "type" : "date_time"]
        _session.send(data: params)
    }
    
    func fetchToken()
    {
//        {"token" : 0, "msg_id" : 257}
        let params:[String:Any] = ["token" : 0, "msg_id" : RemoteCommand.fetchToken.rawValue]
        _session.send(data: params)
    }
    
    func fetchVersion()
    {
//        {"token" : 1, "msg_id" : 11}
        let params:[String:Any] = ["token" : self.token, "msg_id" : RemoteCommand.fetchVersion.rawValue]
        _session.send(data: params)
    }
    
    func fetchHierarchy()
    {
//        {"token" : 1, "msg_id" : 1280}
        let params:[String:Any] = ["token" : self.token, "msg_id" : RemoteCommand.fetchHierarchy.rawValue]
        _session.send(data: params)
    }
    
    func fetchEventVideos()
    {
//        {"token" : 1, "msg_id" : 1289, "param" : 0}
        let params:[String:Any] = ["token" : self.token, "msg_id" : RemoteCommand.fetchEventVideos.rawValue, "param" : 0]
        _session.send(data: params)
    }
    
    func fetchRouteVideos()
    {
        let params:[String:Any] = ["token" : self.token, "msg_id" : RemoteCommand.fetchRouteVideos.rawValue, "param" : 0]
        _session.send(data: params)
    }
    
    func fetchImages()
    {
        let params:[String:Any] = ["token" : self.token, "msg_id" : RemoteCommand.fetchImages.rawValue, "param" : 0]
        _session.send(data: params)
    }
    
    func capture()
    {
//        { "msg_id": 7, "type": "photo_taken", "param": "\/mnt\/mmc01\/PICTURE\/ch1_20170629_1924_0037.jpg" }
        let name = "\(_dateFormatter.string(from: Date())).jpg"
        let params:[String:Any] = ["msg_id": RemoteCommand.capture.rawValue, "type": "photo_taken", "param": "/mnt/mmc01/PICTURE/\(name)"]
        _session.send(data: params)
    }
    
    func record()
    {
//        { "msg_id": 7, "type": "record", "param": "record" }
        let params:[String:Any] = ["msg_id": RemoteCommand.capture.rawValue, "type": "record", "param": "record"]
        _session.send(data: params)
    }
}
