//
//  ScreenRecorder.swift
//  VideoDecode
//
//  Created by larryhou on 10/01/2018.
//  Copyright © 2018 larryhou. All rights reserved.
//

import Foundation
import ReplayKit
import AVKit
import UIKit.UIGestureRecognizerSubclass

@available(iOS 10.0, *)
extension RPSampleBufferType:CustomStringConvertible
{
    public var description:String
    {
        switch self
        {
            case .audioApp:return "audio_app"
            case .audioMic:return "audio_mic"
            case .video:return "video"
        }
    }
}

@objc public class MovieEditInstruction:NSObject
{
    let range:CMTimeRange
    let comment:String
    
    init(range:CMTimeRange, comment:String)
    {
        self.range = range
        self.comment = comment
    }
}

class UITouchGestureRecognizer:UIGestureRecognizer
{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent)
    {
        self.state = .began
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent)
    {
        self.state = .changed
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent)
    {
        self.state = .ended
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent)
    {
        self.state = .cancelled
    }
}

extension Double
{
    var seconds:Double {return floor(self * Double(PREFER_TIMESCALE)) / Double(PREFER_TIMESCALE)}
}

@objc public enum ScreenRecordStatus:Int
{
    case idle, starting, recording, stopping, editing, complete, error
    public var description:String
    {
        switch self
        {
            case .idle: return "idle"
            case .starting: return "starting"
            case .recording: return "recording"
            case .stopping: return "stopping"
            case .editing: return "editing"
            case .complete: return "complete"
            case .error: return "error"
        }
    }
}

fileprivate let recordMovie = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("record.mp4")


@available(iOS 11.0, *)
public class ScreenRecorder:NSObject
{
    @objc public static let shared:ScreenRecorder = ScreenRecorder(cameraViewport: CGSize(width: 100, height: 100))
    
    private let cameraViewport:CGSize
    private var writer:AssetWriter!
    
    private var syncdata:[[Double]] = []
    private let composedMovie:URL
    
    @objc public var statusObserver:((ScreenRecordStatus)->Void)?
    @objc public var status:ScreenRecordStatus = .idle
    {
        didSet { statusObserver?(status) }
    }
    
    init(cameraViewport:CGSize = CGSize(width: 50, height: 50))
    {
        self.cameraViewport = cameraViewport
        self.composedMovie = AssetManager.shared.composedMovie
    }
    
    @objc public var isRecording:Bool { return RPScreenRecorder.shared().isRecording }
    @objc public var reviewEnabled = false
    
    @objc public func cleanup()
    {
        AssetManager.shared.cleanupStorage(type: .editor)
        do{try FileManager.default.removeItem(at: recordMovie)}catch{debug.print(error)}
    }
    
    @objc public func requestCameraAuthorization(completion:@escaping ()->Void)
    {
        requestCaptureAuthorization(for: .video, completion: completion)
    }
    
    @objc public func requestMicrophoneAuthorization(completion:@escaping ()->Void)
    {
        requestCaptureAuthorization(for: .audio, completion: completion)
    }
    
    private func requestCaptureAuthorization(for type:AVMediaType, completion:@escaping ()->Void)
    {
        let status = AVCaptureDevice.authorizationStatus(for: type)
        if status == .authorized
        {
            completion()
        }
        else
        {
            AVCaptureDevice.requestAccess(for: type)
            { (granted) in
                if granted {completion()}
            }
        }
    }
    
    @objc public func startRecording(completion:((Error?)->Void)? = nil)
    {
        writer = try! AssetWriter(url: recordMovie)
        
        synctime = kCMTimeZero
        syncdata.removeAll()
        
        debug.print("[ScreenRecorder]", "startRecording(completion:)", "availableSpace:\(AssetManager.shared.availableSpace) recordingAvailable:\(AssetManager.shared.recordingAvailable)")
        status = .starting
        let recorder = RPScreenRecorder.shared()
        recorder.startCapture(handler: receiveScreenSample(sample:type:error:))
        { (error) in
            completion?(error)
            debug.print("[ScreenRecorder]", "RPScreenRecorder.startCapture(handler:completionHandler:)", error ?? "success")
            self.status = error == nil ? .recording : .error
            guard error == nil else {return}
            DispatchQueue.main.async
            {
                self.setupCamera()
                if let cameraView = recorder.cameraPreviewView
                {
                    cameraView.frame = CGRect(origin: CGPoint.zero, size: self.cameraViewport)
                    cameraView.mask = self.drawCameraShape(size: self.cameraViewport)
                    if let rootView = UIApplication.shared.keyWindow?.rootViewController?.view
                    {
                        let options:UIViewAnimationOptions = [.curveLinear, .transitionCrossDissolve]
                        UIView.transition(with: rootView, duration: 1.0, options: options, animations:
                        {
                            rootView.addSubview(cameraView)
                        }, completion: nil)
                    }
                }
            }
        }
    }
    
    //MARK: camera
    private func setupCamera()
    {
        guard let cameraView = RPScreenRecorder.shared().cameraPreviewView else {return}
        if cameraView.constraints.count > 0 {return}
        
        debug.print("[ScreenRecorder]", "setupCamera")
        
        let tap = UITouchGestureRecognizer(target: self, action: #selector(changeCamera(_:)))
        cameraView.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(moveCameraPreview(_:)))
        pan.maximumNumberOfTouches = 1
        cameraView.addGestureRecognizer(pan)
        tap.require(toFail: pan)
    }
    
    @objc private func moveCameraPreview(_ gesture:UIPanGestureRecognizer)
    {
        guard let view = gesture.view else {return}
        switch gesture.state
        {
            case .began:
                gesture.setTranslation(CGPoint.zero, in: view)
            case .changed:
                let translation = gesture.translation(in: view)
                view.frame = view.frame.offsetBy(dx: translation.x, dy: translation.y)
                gesture.setTranslation(CGPoint.zero, in: view)
            case .ended:
                let bounds = UIScreen.main.bounds, frame = view.frame
                var offset = CGPoint.zero
                if frame.maxX > bounds.width
                {
                    offset.x = bounds.width - frame.maxX
                }
                else if frame.minX < 0
                {
                    offset.x = -frame.minX
                }
            
                if frame.maxY > bounds.height
                {
                    offset.y = bounds.height - frame.maxY
                }
                else if frame.minY < 0
                {
                    offset.y = -frame.minY
                }
                UIView.animate(withDuration: 0.5)
                {
                    view.frame = frame.offsetBy(dx: offset.x, dy: offset.y)
                }
            default:break
        }
    }
    
    @objc private func changeCamera(_ gesture:UITouchGestureRecognizer)
    {
        guard gesture.state == .began else { return }
        if gesture.numberOfTouches >= 2
        {
            let position = RPScreenRecorder.shared().cameraPosition
            switch position
            {
                case .back: RPScreenRecorder.shared().cameraPosition = .front
                case .front: RPScreenRecorder.shared().cameraPosition = .back
            }
        }
        else
        {
            if let view = RPScreenRecorder.shared().cameraPreviewView
            {
                let alpha:CGFloat
                if view.alpha == 1.0
                {
                    alpha = 0.2
                }
                else
                {
                    alpha = 1.0
                }
                
                view.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.2)
                {
                    view.alpha = alpha
                }
            }
        }
    }
    
    private func drawCameraShape(size:CGSize)->UIImageView?
    {
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        UIColor.black.setFill()
        context.addEllipse(in: CGRect(origin: CGPoint.zero, size: size))
        context.fillPath()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return UIImageView(image: image)
    }
    
    //MARK: sample
    private var synctime:CMTime = kCMTimeZero
    private func receiveScreenSample(sample:CMSampleBuffer, type:RPSampleBufferType, error:Error?)
    {
        guard status == .recording else {return}
        if !synctime.isValid {synctime = kCMTimeZero}
        if error == nil
        {
            writer.append(sample: sample, type: type)
            if type == .video
            {
                let position = CMSampleBufferGetPresentationTimeStamp(sample) - writer.timeOffset
                if Int(position.seconds) % 5 == 0 && (position - synctime).seconds >= 1
                {
                    synctime = position
                    synchronize(timestamp: position.seconds)
                }
            }
        }
        else
        {
            status = .error
            debug.print(error ?? sample)
        }
    }
    
    
    @objc public var requestUnityTime:(()->Void)? // get game timestamp for timesync
    private func synchronize(timestamp value:Double)
    {
        print("[ScreenRecorder]", "synchronize(timestamp:)", value)
        requestUnityTime?()
    }
    
    @objc public func appendUnityTime(_ value:Double)
    {
        print("[ScreenRecorder]", "appendUnityTime(_:)", value, synctime.seconds - value)
        if !value.isNaN && !synctime.seconds.isNaN
        {
            syncdata.append([synctime.seconds, value])
        }
    }
    
    @objc public func startMovieEditProcess(clipContext:String? = nil, summary:String? = nil, keepClips:Bool, completion:((URL, String?)->Void)? = nil)
    {
        guard let clipContext = clipContext, clipContext.count > 0 else
        {
            status = .error
            debug.print("[ScreenRecorder]", "startExportSession(clipContext:completion:) invalid context")
            completion?(recordMovie, nil)
            return
        }
        
        status = .editing
        AssetManager.shared.cleanupStorage(type: .editor)
        
        debug.print("[ScreenRecorder]", "startExportSession(clipContext:completion:) call", clipContext)
        
        let offset:Double
        if syncdata.count > 0
        {
            let samples = syncdata.map({ $0[0] - $0[1] })
            offset = samples.reduce(0, { $0 + $1 }) / Double(samples.count)
            debug.print("[ScreenRecorder]", "SYNC", samples, "OFFSET", offset)
        }
        else
        {
            offset = 0
        }
        
        let instructions = clipContext.split(separator: ";").map
        { (item) -> MovieEditInstruction in
            let data = item.split(separator: "|")
            let pair = data[1].split(separator: "-").map({Double($0) ?? .nan})
            let f = CMTime(seconds: (pair[0] + offset).seconds, preferredTimescale: PREFER_TIMESCALE)
            let t = CMTime(seconds: (pair[1] + offset).seconds, preferredTimescale: PREFER_TIMESCALE)
            return MovieEditInstruction(range: CMTimeRange(start: f, end: t), comment: String(data[0]))
        }.filter({$0.range.start.value >= 0})
        
        if FileManager.default.fileExists(atPath: composedMovie.path)
        {
            try? FileManager.default.removeItem(at: composedMovie)
        }
        
        let editor = MovieEditor(transition: .dissolve, transitionDuration: 1.0)
        let attributes = AssetManager.shared.attributes(of: recordMovie.path)
        debug.print("[ScreenRecorder]", "MovieEditor.cut(asset:with:summary:exportClips:transition:completion:) call attributes:\(attributes)")
        editor.cut(asset: AVAsset(url: recordMovie), with: instructions, summary: summary, exportClips: keepClips)
        {
            let editJSON = AssetManager.shared.editJSON
            self.status = editJSON == nil ? .error : .complete
            debug.print("[ScreenRecorder]", "MovieEditor.cut(asset:with:summary:exportClips:transition:completion:) completion", editJSON ?? "nil")
            completion?(self.composedMovie, editJSON)
            if self.reviewEnabled
            {
                self.reviewMovie(self.composedMovie)
            }
            
//            do{try FileManager.default.removeItem(at: recordMovie)}catch{logger.print(error)}
        }
    }
    
    private var exporter:AVAssetExportSession!
    @objc public func stopRecording(clipContext:String? = nil, summary:String? = nil, completion:((URL, String?)->Void)? = nil, keepClips:Bool = true)
    {
        if !isRecording
        {
            status = .error
            completion?(recordMovie, nil)
            return
        }
        
        synchronize(timestamp: .nan)
        
        status = .stopping
        debug.print("[ScreenRecorder]", "stopRecording(clipContext:completion:) call", clipContext ?? "clipContext = nil")
        RPScreenRecorder.shared().stopCapture
        { (error) in
            debug.print("[ScreenRecorder]", "RPScreenRecorder.stopCapture(handler:)", error ?? "success")
            DispatchQueue.main.async
            {
                self.writer.save
                {
                    self.startMovieEditProcess(clipContext: clipContext, summary: summary, keepClips: keepClips, completion: completion)
                }
                
                if let cameraView = RPScreenRecorder.shared().cameraPreviewView, let rootView = cameraView.superview
                {
                    let options:UIViewAnimationOptions = [.curveLinear, .transitionCrossDissolve]
                    UIView.transition(with: rootView, duration: 0.25, options: options, animations:
                    {
                        cameraView.removeFromSuperview()
                    }, completion: nil)
                }
            }
        }
    }
    
    private func reviewMovie(_ url:URL)
    {
        debug.print("[ScreenRecorder]", "reviewMovie(_:)")
        AssetManager.shared.playMovie(with: url)
    }
    
    @objc public var progressObserver:((Float)->Void)?
    @objc private func progressUpdate(_ timer:Timer)
    {
//        progressObserver?(exporter.progress)
//        if exporter.progress == 1.0
//        {
//            timer.invalidate()
//        }
    }
    
    @objc public func encode(command:String, data:String)->String?
    {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(MessageProtocol(command: command, data: data))
        {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}

extension AVAssetWriterStatus:CustomStringConvertible
{
    public var description:String
    {
        switch self
        {
            case .cancelled:return "cancelled"
            case .completed:return "completed"
            case .writing:return "writing"
            case .unknown:return "unknown"
            case .failed:return "failed"
        }
    }
}

@available(iOS 11.0, *)
class AssetWriter
{
    private let writer:AVAssetWriter
    let url:URL
    
    private var movieTracks:[RPSampleBufferType:AVAssetWriterInput] = [:]
    
    init(url:URL) throws
    {
        self.url = url
        if FileManager.default.fileExists(atPath: url.path)
        {
            try? FileManager.default.removeItem(at: url)
        }
        
        self.writer = try AVAssetWriter(url: url, fileType: .mp4)
        self.writer.movieTimeScale = 600
    }
    
    private var initialized = false
    private func setup(sample:CMSampleBuffer)
    {
        if (initialized) { return }
        initialized = true
        
        let screen = UIScreen.main.bounds
        let width:CGFloat = 720
        let height = round(width * screen.height / screen.width)
        
        let videoOptions:[String:Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width, AVVideoHeightKey: height]
        movieTracks[.video] = AVAssetWriterInput(mediaType: .video, outputSettings: videoOptions)
        
        if let format = CMSampleBufferGetFormatDescription(sample), let stream = CMAudioFormatDescriptionGetStreamBasicDescription(format)
        {
            let audioOptions:[String:Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: stream.pointee.mChannelsPerFrame,
                AVSampleRateKey: stream.pointee.mSampleRate]
            movieTracks[.audioApp] = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOptions)
            if RPScreenRecorder.shared().isMicrophoneEnabled
            {
                movieTracks[.audioMic] = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOptions)
            }
        }
        else
        {
            let audioOptions:[String:Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100]
            movieTracks[.audioApp] = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOptions)
        }
        
        for (type, track) in movieTracks
        {
            track.expectsMediaDataInRealTime = true
            if writer.canAdd(track)
            {
                writer.add(track)
            }
            else
            {
                debug.print("[AssetWriter] AVAssetWriter.add(_:AVAssetWriterInput#\(type)) failure")
            }
        }
        
        timeOffset = CMSampleBufferGetPresentationTimeStamp(sample)
        
        writer.startWriting()
        writer.startSession(atSourceTime: timeOffset)
        debug.print("[AssetWriter]", "AVAssetWriter.startSession(atSourceTime:\(timeOffset.seconds)")
        assetWriting = true
    }
    
    private(set) var timeOffset:CMTime = kCMTimeZero
    
    private let background = DispatchQueue(label: "video_encode_queue")
    func append(sample:CMSampleBuffer, type:RPSampleBufferType)
    {
        guard CMSampleBufferIsValid(sample) else {return}
        
        background.sync
        {
            if !initialized
            {
                setup(sample: sample)
            }
            
            guard writer.status == .writing, assetWriting else {return}
            
            if let track = movieTracks[type], track.isReadyForMoreMediaData
            {
                if type == .video
                {
                    track.append(sample)
                    if let error = writer.error
                    {
                        debug.print("[AssetWriter] append(sample:type:\(type)", error)
                    }
                }
                else
                {
                    track.append(sample)
                    if let error = writer.error
                    {
                        debug.print("[AssetWriter] append(sample:type:\(type)", error)
                    }
                }
            }
        }
    }
    
    private var assetWriting:Bool = false
    func save(completion:(()->Void)? = nil)
    {
        assetWriting = false
        debug.print("[AssetWriter] save(completion:)", "call status:\(self.writer.status)")
        guard self.writer.status == .writing else
        {
            debug.print("[AssetWriter] save(completion:)", "failure status:\(self.writer.status)")
            return
        }
        
        self.writer.finishWriting
        {
            debug.print("[AssetWriter] save(completion:)", "finish status:\(self.writer.status)", self.writer.error ?? "success")
            completion?()
        }
    }
}

struct MessageProtocol:Codable
{
    let command:String
    let data:String?
}
