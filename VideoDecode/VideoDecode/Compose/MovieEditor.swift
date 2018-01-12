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

enum VideoTransition
{
    case DISSOLVE, PUSH_RIGHT, PUSH_LEFT, PUSH_TOP, PUSH_BOTTOM, ERASE_RIGHT, ERASE_LEFT, ERASE_TOP, ERASE_BOTTOM, RANDOM
}

class MovieEditor
{
    private(set) var asset:AVAsset!
    private(set) var insertClips:[CMTimeRange]!
    
    private var assetComposition:AVMutableComposition!
    private var transitionClips:[CMTimeRange]!
    private var passClips:[CMTimeRange]!
    
    var videoTransition:VideoTransition
    var transitionDuration:TimeInterval
    
    init(transition:VideoTransition = .DISSOLVE, transitionDuration duration:TimeInterval = 1.0)
    {
        self.videoTransition = transition
        self.transitionDuration = duration
    }
    
    func cut(asset:AVAsset, with clips:[CMTimeRange], transition:VideoTransition? = nil)->AVAssetExportSession?
    {
        guard asset.isReadable else { return nil }
        let insertClips:[CMTimeRange] = clips.filter({ !$0.duration.seconds.isNaN })
        guard insertClips.count > 0 else { return nil }
        
        if let transition = transition
        {
            self.videoTransition = transition
        }
        
        self.asset = asset
        self.insertClips = insertClips
        
        self.assetComposition = AVMutableComposition()
        let exporter = AVAssetExportSession(asset: assetComposition, presetName: AVAssetExportPreset1280x720)
        if let (videoComposition, mix) = composeMovieTracks()
        {
            exporter?.videoComposition = videoComposition
            exporter?.audioMix = mix
        }
        exporter?.outputFileType = AVFileType.mp4
        return exporter
    }
    
    private func composeMovieTracks()->(AVMutableVideoComposition, AVMutableAudioMix)?
    {
        let videoTracks = [
            assetComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!,
            assetComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!]
        let audioTracks = [
            assetComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!,
            assetComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!]
        
        self.transitionClips = []
        self.passClips = []
        
        let assetVideoTracks = asset.tracks(withMediaType: .video)
        let assetAudioTracks = asset.tracks(withMediaType: .audio)
        
        let extraTracks:[AVMutableCompositionTrack]?
        if assetAudioTracks.count > 1
        {
            extraTracks = [
            assetComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!,
            assetComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!]
        }
        else
        {
            extraTracks = nil
        }
        
        var anchor = kCMTimeZero
        let overlap = CMTime(seconds: transitionDuration, preferredTimescale: 100)
        for i in 0..<insertClips.count
        {
            let index = i % 2
            let range = insertClips[i]
            try? videoTracks[index].insertTimeRange(range, of: assetVideoTracks[0], at: anchor)
            try? audioTracks[index].insertTimeRange(range, of: assetAudioTracks[0], at: anchor)
            try? extraTracks?[index].insertTimeRange(range, of: assetAudioTracks[1], at: anchor)
            
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
            let instruction = AVMutableVideoCompositionInstruction()
            let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTracks[index])
            instruction.layerInstructions = [layer]
            instruction.timeRange = passClips[i]
            videoInstuctions.append(instruction)
            
            if i < transitionClips.count
            {
                let range = transitionClips[i]
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.layerInstructions = getTransitionInstuctions(srcTrack: videoTracks[index], dstTrack: videoTracks[1-index], range: range, transition: videoTransition)
                instruction.timeRange = range
                videoInstuctions.append(instruction)
                
                mixParameters.append(contentsOf: getMixParameters(srcTrack: audioTracks[index], dstTrack: audioTracks[1-index], range: transitionClips[i]))
                if let extraTracks = extraTracks
                {
                    mixParameters.append(contentsOf: getMixParameters(srcTrack: extraTracks[index], dstTrack: extraTracks[1-index], range: transitionClips[i]))
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
            case .DISSOLVE:
                return dissolve(srcTrack: srcTrack, dstTrack: dstTrack, range: range)
            case .PUSH_RIGHT:
                return push(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .right)
            case .PUSH_LEFT:
                return push(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .left)
            case .PUSH_TOP:
                return push(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .top)
            case .PUSH_BOTTOM:
                return push(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .bottom)
            case .ERASE_RIGHT:
                return erase(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .right)
            case .ERASE_LEFT:
                return erase(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .left)
            case .ERASE_TOP:
                return erase(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .top)
            case .ERASE_BOTTOM:
                return erase(srcTrack: srcTrack, dstTrack: dstTrack, range: range, direction: .bottom)
            case .RANDOM:
                let transitions:[VideoTransition] = [.DISSOLVE, .PUSH_TOP, .PUSH_BOTTOM, .PUSH_LEFT, .PUSH_RIGHT, .ERASE_TOP, .ERASE_BOTTOM, .ERASE_RIGHT, .ERASE_LEFT]
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
