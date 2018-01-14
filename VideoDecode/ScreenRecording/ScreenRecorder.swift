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

fileprivate let recordMovie = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("record.mp4")
fileprivate let exportMovie = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("export.mp4")

public class ScreenRecorder:NSObject
{
    @objc public static let shared:ScreenRecorder = ScreenRecorder(cameraViewport: CGSize(width: 100, height: 100))
    
    private let cameraViewport:CGSize
    private var writer:AssetWriter!
    
    private var syncdata:[[Double]] = []
    
    init(cameraViewport:CGSize = CGSize(width: 50, height: 50))
    {
        self.cameraViewport = cameraViewport
    }
    
    @objc public var isRecording:Bool { return RPScreenRecorder.shared().isRecording }
    
    @objc public func startRecording(completion:((Error?)->Void)? = nil)
    {
        writer = try! AssetWriter(url: recordMovie)
        syncdata.removeAll()
        
        let recorder = RPScreenRecorder.shared()
        recorder.isMicrophoneEnabled = true
        recorder.isCameraEnabled = true
        recorder.cameraPosition = .front
        recorder.startCapture(handler: receiveScreenSample(sample:type:error:))
        { (error) in
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
                
                completion?(error)
            }
        }
    }
    
    //MARK: camera
    private func setupCamera()
    {
        guard let cameraView = RPScreenRecorder.shared().cameraPreviewView else {return}
        if cameraView.constraints.count > 0 {return}
        
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
            print(error ?? CMSampleBufferGetPresentationTimeStamp(sample).seconds)
        }
    }
    
    @objc public var fetchUnityTime:(()->Double)? // get game timestamp for timesync
    private func synchronize(timestamp value:Double)
    {
        print("sychronize", value)
        if let time = fetchUnityTime?()
        {
            syncdata.append([value, time])
        }
    }
    
    private func startExportSession(clipContext:String? = nil, completion:((URL, AVAssetExportSessionStatus)->Void)? = nil)
    {
        guard let clipContext = clipContext else
        {
            completion?(recordMovie, .cancelled)
            return
        }
        
        let offset:Double
        if syncdata.count > 0
        {
            let samples = syncdata.map({ $0[0] - $0[1] })
            offset = samples.reduce(0, { $0 + $1 }) / Double(samples.count)
            print("[SYNC]", samples, "OFFSET", offset)
        }
        else
        {
            offset = 0
        }
        
        let clips = clipContext.split(separator: ";").map
        { (item) -> CMTimeRange in
            let pair = item.split(separator: "-").map({Double($0) ?? .nan})
            let f = CMTime(seconds: pair[0] + offset, preferredTimescale: 600)
            let t = CMTime(seconds: pair[1] + offset, preferredTimescale: 600)
            return CMTimeRange(start: f, end: t)
        }
        
        if FileManager.default.fileExists(atPath: exportMovie.path)
        {
            try? FileManager.default.removeItem(at: exportMovie)
        }
        
        let editor = MovieEditor(transition: .dissolve, transitionDuration: 1.0)
        if let exporter = editor.cut(asset: AVAsset(url: recordMovie), with: clips)
        {
            self.exporter = exporter
            exporter.outputURL = exportMovie
            exporter.exportAsynchronously
            {
                DispatchQueue.main.async
                {
                    completion?(exportMovie, exporter.status)
                    self.reviewMovie(exportMovie)
                }
            }
            Timer.scheduledTimer(timeInterval: 1/30, target: self, selector: #selector(progressUpdate(_:)), userInfo: nil, repeats: true)
        }
    }
    
    private var exporter:AVAssetExportSession!
    @objc public func stopRecording(clipContext:String? = nil, completion:((URL, AVAssetExportSessionStatus)->Void)? = nil)
    {
        RPScreenRecorder.shared().stopCapture
        { (error) in
            print(error ?? "stop success")
            DispatchQueue.main.async
            {
                self.writer.save
                {
                    self.startExportSession(clipContext: clipContext, completion: completion)
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
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        {
            let player = AVPlayer(url: url)
            let reviewController = AVPlayerViewController()
            reviewController.player = player
            rootViewController.present(reviewController, animated: true, completion: nil)
            player.play()
        }
    }
    
    @objc public var progressObserver:((Float)->Void)?
    @objc private func progressUpdate(_ timer:Timer)
    {
        progressObserver?(exporter.progress)
        if exporter.progress == 1.0
        {
            timer.invalidate()
        }
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
        
        let videoOptions:[String:Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: UIScreen.main.bounds.width, AVVideoHeightKey: UIScreen.main.bounds.height]
        movieTracks[.video] = AVAssetWriterInput(mediaType: .video, outputSettings: videoOptions)
        
        if let format = CMSampleBufferGetFormatDescription(sample), let stream = CMAudioFormatDescriptionGetStreamBasicDescription(format)
        {
            let audioOptions:[String:Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: stream.pointee.mChannelsPerFrame,
                AVSampleRateKey: stream.pointee.mSampleRate]
            movieTracks[.audioApp] = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOptions)
            movieTracks[.audioMic] = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOptions)
            
            for (type, track) in movieTracks
            {
                track.expectsMediaDataInRealTime = true
                if writer.canAdd(track)
                {
                    writer.add(track)
                }
                else
                {
                    print("[AssetWriter] add track[\(type)] input fails")
                }
            }
        }
        
        timeOffset = CMSampleBufferGetPresentationTimeStamp(sample)
        
        writer.startWriting()
        writer.startSession(atSourceTime: timeOffset)
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
            
            if let track = movieTracks[type], track.isReadyForMoreMediaData
            {
                if type == .video
                {
                    track.append(sample)
                    if writer.status == .failed
                    {
                        print(type, writer.error!)
                    }
                }
                else
                {
                    track.append(sample)
                    if writer.status == .failed
                    {
                        print(type, writer.error!)
                    }
                }
            }
        }
    }
    
    func save(completion:(()->Void)? = nil)
    {
        self.writer.finishWriting
        {
            print("finish", self.writer.status, self.writer.error ?? "success")
            completion?()
        }
    }
}
