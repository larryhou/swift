//
//  MovieEditor.swift
//  VideoDecode
//
//  Created by larryhou on 09/01/2018.
//  Copyright © 2018 larryhou. All rights reserved.
//

import Foundation
import AVFoundation
import GameplayKit

let PREFER_TIMESCALE:Int32 = 60000

extension AVAssetExportSessionStatus:CustomStringConvertible
{
    public var description:String
    {
        switch self
        {
            case .cancelled:return "cancelled"
            case .exporting:return "exporting"
            case .completed:return "completed"
            case .waiting:return "waiting"
            case .unknown:return "unknown"
            case .failed:return "failed"
        }
    }
}

fileprivate enum VideoTransitionDirection
{
    case right, left, top, bottom
}

@available(iOS 10.0, *)
@objc public enum VideoTransition:Int
{
    case dissolve, pushRight, pushLeft, pushTop, pushBottom, eraseRight, eraseLeft, eraseTop, eraseBottom, random
}

struct ExportSessionInstruction
{
    let session:AVAssetExportSession
    let comment:String
}

@available(iOS 10.0, *)
public class MovieEditor:NSObject
{
    private(set) var asset:AVAsset!
    private(set) var insertClips:[CMTimeRange]!
    
    private var assetComposition:AVMutableComposition!
    private var transitionClips:[CMTimeRange]!
    private var passClips:[CMTimeRange]!
    
    var videoTransition:VideoTransition
    var transitionDuration:TimeInterval
    
    @objc public init(transition:VideoTransition = .dissolve, transitionDuration duration:TimeInterval = 1.0)
    {
        self.videoTransition = transition
        self.transitionDuration = duration
    }
    
    @objc public func cut(asset:AVAsset, with instructions:[MovieEditInstruction], summary:String? = nil, exportClips:Bool = true, transition:VideoTransition = .dissolve, completion:(()->Void)? = nil)
    {
        guard asset.isReadable else
        {
            debug.print("[MovieEditor] cut(asset:with:transition:completion:)", "error: asset.isReadable = false")
            completion?();
            return
        }
        
        debug.print("[MovieEditor] cut(asset:with:transition:completion:) duration:\(asset.duration) \(asset.duration.seconds)")
        let instructions:[MovieEditInstruction] = instructions.filter({ !$0.range.duration.seconds.isNaN })
        guard instructions.count > 0 else { completion?(); return }
        
        self.videoTransition = transition
        
        self.asset = asset
        self.insertClips = instructions.map({$0.range})
        
        self.assetComposition = AVMutableComposition()
        let exporter = AVAssetExportSession(asset: assetComposition, presetName: AVAssetExportPreset1280x720)
        if let (videoComposition, mix) = composeMovieTracks()
        {
            exporter?.videoComposition = videoComposition
            exporter?.audioMix = mix
        }
        exporter?.outputFileType = .mp4
        exporter?.outputURL = AssetManager.shared.composedMovie
        
        var sessionInstructions:[ExportSessionInstruction] = []
        if exportClips
        {
            let clipSessions = composeMovieClips(asset: asset, with: instructions)
            for i in 0..<clipSessions.count
            {
                sessionInstructions.append(ExportSessionInstruction(session: clipSessions[i], comment: instructions[i].comment))
            }
        }
        
        if let exporter = exporter
        {
            sessionInstructions.append(ExportSessionInstruction(session: exporter, comment: summary ?? ""))
        }
        
        AssetManager.shared.processMovieSessions(instructions: sessionInstructions)
        {
            DispatchQueue.main.async
            {
                completion?()
            }
        }
    }
    
    func composeMovieClips(asset:AVAsset, with clips:[MovieEditInstruction])->[AVAssetExportSession]
    {
        debug.print("[MovieEditor] composeMovieClips(asset:with:)")
        let assetVideoTracks = asset.tracks(withMediaType: .video)
        let assetAudioTracks = asset.tracks(withMediaType: .audio)
        
        var exportSessions:[AVAssetExportSession] = []
        do
        {
            for index in 0..<clips.count
            {
                let range = clips[index].range
                debug.print("[MovieEditor]", "\(index + 1)/\(clips.count)", range)
                let composition = AVMutableComposition()
                for track in assetVideoTracks
                {
                    let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                    try videoTrack?.insertTimeRange(range, of: track, at: kCMTimeZero)
                }
                
                for track in assetAudioTracks
                {
                    let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                    try audioTrack?.insertTimeRange(range, of: track, at: kCMTimeZero)
                }
                
                if let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPreset1280x720)
                {
                    session.outputFileType = .mp4
                    session.outputURL = AssetManager.shared.getEditorMovieURL(with: index)
                    exportSessions.append(session)
                }
            }
        }
        catch {debug.print(error)}
        return exportSessions
    }
    
    typealias TransitionTrack = [AVMutableCompositionTrack]
    private func composeMovieTracks()->(AVMutableVideoComposition, AVMutableAudioMix)?
    {
        debug.print("[MovieEditor] composeMovieTracks")
        
        self.transitionClips = []
        self.passClips = []
        
        let assetVideoTracks = asset.tracks(withMediaType: .video)
        let assetAudioTracks = asset.tracks(withMediaType: .audio)
        
        var videoTracks:[TransitionTrack] = []
        for _ in 0..<assetVideoTracks.count
        {
            let track = [
                assetComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!,
                assetComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!]
            videoTracks.append(track)
        }
        
        var audioTracks:[TransitionTrack] = []
        for _ in 0..<assetAudioTracks.count
        {
            let track = [
                assetComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!,
                assetComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!]
            audioTracks.append(track)
        }
        
        var anchor = kCMTimeZero
        let overlap = CMTime(seconds: transitionDuration, preferredTimescale: PREFER_TIMESCALE)
        for i in 0..<insertClips.count
        {
            let index = i % 2
            let range = insertClips[i]
            
            for n in 0..<assetVideoTracks.count
            {
                let assetTrack = assetVideoTracks[n]
                try? videoTracks[n][index].insertTimeRange(range, of: assetTrack, at: anchor)
            }
            
            for n in 0..<assetAudioTracks.count
            {
                let assetTrack = assetAudioTracks[n]
                try? audioTracks[n][index].insertTimeRange(range, of: assetTrack, at: anchor)
            }
            
            var passClip = CMTimeRange(start: anchor, duration: range.duration)
            if i > 0
            {
                passClip.start = passClip.start + overlap
                passClip.duration = passClip.duration - overlap
            }
            
            if i + 1 < insertClips.count
            {
                passClip.duration = passClip.duration - overlap
            }
            
            passClips.append(passClip)
            
            anchor = anchor + range.duration - overlap
            if i + 1 < insertClips.count
            {
                transitionClips.append(CMTimeRange(start: anchor, duration: overlap))
            }
        }
        
        var mixParameters:[AVMutableAudioMixInputParameters] = []
        var videoInstuctions:[AVMutableVideoCompositionInstruction] = []
        for i in 0..<passClips.count
        {
            let index = i % 2
            for n in 0..<videoTracks.count
            {
                let instruction = AVMutableVideoCompositionInstruction()
                let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTracks[n][index])
                instruction.layerInstructions = [layer]
                instruction.timeRange = passClips[i]
                videoInstuctions.append(instruction)
            }
            
            if i < transitionClips.count
            {
                let range = transitionClips[i]
                for n in 0..<videoTracks.count
                {
                    let instruction = AVMutableVideoCompositionInstruction()
                    instruction.layerInstructions = getTransitionInstuctions(srcTrack: videoTracks[n][index], dstTrack: videoTracks[n][1-index], range: range, transition: videoTransition)
                    instruction.timeRange = range
                    videoInstuctions.append(instruction)
                }
                
                for n in 0..<audioTracks.count
                {
                    mixParameters.append(contentsOf: getMixParameters(srcTrack: audioTracks[n][index], dstTrack: audioTracks[n][1-index], range: transitionClips[i]))
                }
            }
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = assetVideoTracks[0].naturalSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = videoInstuctions
        
        let mix = AVMutableAudioMix()
        mix.inputParameters = mixParameters
        return (videoComposition, mix)
    }
    
    private func getMixParameters(srcTrack:AVMutableCompositionTrack, dstTrack:AVMutableCompositionTrack, range:CMTimeRange)->[AVMutableAudioMixInputParameters]
    {
        var result:[AVMutableAudioMixInputParameters] = []
        var parameter = AVMutableAudioMixInputParameters(track: srcTrack)
        parameter.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 0.0, timeRange: range)
        parameter.setVolume(1.0, at: range.end)
        result.append(parameter)
        
        parameter = AVMutableAudioMixInputParameters(track: dstTrack)
        parameter.setVolumeRamp(fromStartVolume: 0.0, toEndVolume: 1.0, timeRange: range)
        result.append(parameter)
        return result
    }
    
    private func getTransitionInstuctions(srcTrack:AVMutableCompositionTrack, dstTrack:AVMutableCompositionTrack, range:CMTimeRange, transition:VideoTransition)->[AVMutableVideoCompositionLayerInstruction]
    {
        switch transition
        {
            case .dissolve:
                return dissolve(srcTrack: srcTrack, dstTrack: dstTrack, range: range)
            case .pushRight:
                return push(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .right)
            case .pushLeft:
                return push(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .left)
            case .pushTop:
                return push(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .top)
            case .pushBottom:
                return push(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .bottom)
            case .eraseRight:
                return erase(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .right)
            case .eraseLeft:
                return erase(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .left)
            case .eraseTop:
                return erase(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .top)
            case .eraseBottom:
                return erase(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .bottom)
            case .random:
                let transitions:[VideoTransition] = [.dissolve, .pushTop, .pushBottom, .pushLeft, .pushRight, .eraseTop, .eraseBottom, .eraseRight, .eraseLeft]
                let index = Int(GKRandomSource.sharedRandom().nextUniform() * Float(transitions.count))
                return getTransitionInstuctions(srcTrack: srcTrack, dstTrack: dstTrack, range: range, transition: transitions[index])
        }
    }
    
    private func dissolve(srcTrack:AVMutableCompositionTrack, dstTrack:AVMutableCompositionTrack, range:CMTimeRange)->[AVMutableVideoCompositionLayerInstruction]
    {
        let src = AVMutableVideoCompositionLayerInstruction(assetTrack: srcTrack)
        src.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: range)
        let dst = AVMutableVideoCompositionLayerInstruction(assetTrack: dstTrack)
        dst.setOpacityRamp(fromStartOpacity: 0.0, toEndOpacity: 1.0, timeRange: range)
        return [src, dst]
    }
    
    //MARK: push transition effect
    private func push(srcTrack:AVMutableCompositionTrack, dstTrack:AVMutableCompositionTrack, range:CMTimeRange, direction:VideoTransitionDirection)->[AVMutableVideoCompositionLayerInstruction]
    {
        let size = srcTrack.naturalSize
        let center = CGAffineTransform.identity
        let left = center.translatedBy(x: -size.width, y: 0)
        let right = center.translatedBy(x: size.width, y: 0)
        let top = center.translatedBy(x: 0, y: -size.height)
        let bottom = center.translatedBy(x: 0, y: size.height)
        
        let src = AVMutableVideoCompositionLayerInstruction(assetTrack: srcTrack)
        let dst = AVMutableVideoCompositionLayerInstruction(assetTrack: dstTrack)
        
        switch direction
        {
            case .left:
                src.setTransformRamp(fromStart: center, toEnd: left, timeRange: range)
                dst.setTransformRamp(fromStart: right, toEnd: center, timeRange: range)
            case .right:
                src.setTransformRamp(fromStart: center, toEnd: right, timeRange: range)
                dst.setTransformRamp(fromStart: left, toEnd: center, timeRange: range)
            case .top:
                src.setTransformRamp(fromStart: center, toEnd: top, timeRange: range)
                dst.setTransformRamp(fromStart: bottom, toEnd: center, timeRange: range)
            case .bottom:
                src.setTransformRamp(fromStart: center, toEnd: bottom, timeRange: range)
                dst.setTransformRamp(fromStart: top, toEnd: center, timeRange: range)
        }
        
        return [src, dst]
    }
    
    //MARK: erase transition effect
    private func erase(srcTrack:AVMutableCompositionTrack, dstTrack:AVMutableCompositionTrack, range:CMTimeRange, direction:VideoTransitionDirection)->[AVMutableVideoCompositionLayerInstruction]
    {
        let size = srcTrack.naturalSize
        let full = CGRect(origin: CGPoint.zero, size: size)
        let left = CGRect(origin: CGPoint.zero, size: CGSize(width: 0, height: size.height))
        let right = left.offsetBy(dx: size.width, dy: 0)
        let top = CGRect(origin: CGPoint.zero, size: CGSize(width: size.width, height: 0))
        let bottom = top.offsetBy(dx: 0, dy: size.height)
        
        let src = AVMutableVideoCompositionLayerInstruction(assetTrack: srcTrack)
        let dst = AVMutableVideoCompositionLayerInstruction(assetTrack: dstTrack)
        
        switch direction
        {
            case .left:
                src.setCropRectangleRamp(fromStartCropRectangle: full, toEndCropRectangle: left, timeRange: range)
                dst.setCropRectangleRamp(fromStartCropRectangle: right, toEndCropRectangle: full, timeRange: range)
            case .right:
                src.setCropRectangleRamp(fromStartCropRectangle: full, toEndCropRectangle: right, timeRange: range)
                dst.setCropRectangleRamp(fromStartCropRectangle: left, toEndCropRectangle: full, timeRange: range)
            case .top:
                src.setCropRectangleRamp(fromStartCropRectangle: full, toEndCropRectangle: top, timeRange: range)
                dst.setCropRectangleRamp(fromStartCropRectangle: bottom, toEndCropRectangle: full, timeRange: range)
            case .bottom:
                src.setCropRectangleRamp(fromStartCropRectangle: full, toEndCropRectangle: bottom, timeRange: range)
                dst.setCropRectangleRamp(fromStartCropRectangle: top, toEndCropRectangle: full, timeRange: range)
        }
        
        return [src, dst]
    }
}
