//
//  MovieEditor.swift
//  VideoDecode
//
//  Created by larryhou on 09/01/2018.
//  Copyright © 2018 larryhou. All rights reserved.
//

import Foundation
import AVFoundation

extension AVAssetExportSessionStatus
{
    var description:String
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

extension CMTimeRange
{
    var description:String
    {
        return "f:\(start.seconds) t:\(end.seconds) d:\(duration.seconds)"
    }
}

class MovieEditor
{
    var asset:AVAsset!
    var insertClips:[CMTimeRange]!
    
    var transitionDuration = 1.5
    var assetComposition:AVMutableComposition!
    var transitionClips:[CMTimeRange]!
    var passClips:[CMTimeRange]!
    
    func cut(asset:AVAsset,
             withClips clips:[CMTimeRange])->AVAssetExportSession?
    {
        guard asset.isReadable else { return nil }
        let insertClips:[CMTimeRange] = clips.filter({ !$0.duration.seconds.isNaN })
        guard insertClips.count > 0 else { return nil }
        
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
        
        let assetVideoTrack = asset.tracks(withMediaType: .video)[0]
        let assetAudioTrack = asset.tracks(withMediaType: .audio)[0]
        
        var anchor = kCMTimeZero
        let overlap = CMTime(seconds: transitionDuration, preferredTimescale: 100)
        for i in 0..<insertClips.count
        {
            let index = i % 2
            let range = insertClips[i]
            try? videoTracks[index].insertTimeRange(range, of: assetVideoTrack, at: anchor)
            try? audioTracks[index].insertTimeRange(range, of: assetAudioTrack, at: anchor)
            
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
                let src = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTracks[index])
                src.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: range)
                let dst = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTracks[1 - index])
                dst.setOpacityRamp(fromStartOpacity: 0.0, toEndOpacity: 1.0, timeRange: range)
                instruction.layerInstructions = [src, dst]
                instruction.timeRange = range
                videoInstuctions.append(instruction)
                
                var parameter = AVMutableAudioMixInputParameters(track: audioTracks[index])
                parameter.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 0.0, timeRange: transitionClips[i])
                parameter.setVolume(1.0, at: transitionClips[i].end)
                mixParameters.append(parameter)
                
                parameter = AVMutableAudioMixInputParameters(track: audioTracks[1 - index])
                parameter.setVolume(0.0, at: transitionClips[i].start)
                parameter.setVolumeRamp(fromStartVolume: 0.0, toEndVolume: 1.0, timeRange: transitionClips[i])
                mixParameters.append(parameter)
            }
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = assetVideoTrack.naturalSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = videoInstuctions
        
        let mix = AVMutableAudioMix()
        mix.inputParameters = mixParameters
        return (videoComposition, mix)
    }
}
