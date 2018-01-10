//
//  ViewController.swift
//  MovieEditor
//
//  Created by larryhou on 03/01/2018.
//  Copyright © 2018 larryhou. All rights reserved.
//

import UIKit
import AVFoundation

extension AVAssetReaderStatus
{
    var description:String
    {
        switch self
        {
        case .cancelled: return "cancelled"
        case .completed: return "completed"
        case .reading: return "reading"
        case .unknown: return "unknown"
        case .failed: return "failed"
        }
    }
}

extension CMTime
{
    var realtime:Double {return Double(value) / Double(timescale) }
}

class ViewController: UIViewController
{
    var background = DispatchQueue(label: "track_read_queue")
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var viewport: UIImageView!
    
    var trackOutput:AVAssetReaderTrackOutput!
    var reader:AVAssetReader!
    
    var exporter:AVAssetExportSession!
    
    var outputURL:URL!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        guard let bundle = Bundle.main.path(forResource: "movie", ofType: "bundle") else {return}
        
        let location = URL(fileURLWithPath: "\(bundle)/funny.mp4")
        let asset = AVAsset(url: location)
        
        let duration = asset.duration
        var position = CMTime(value: 0, timescale: duration.timescale)
        
        let CUT_INTERVAL = CMTime(value: 10, timescale: 1)
        let CUT_DURATION = CMTime(value: 5, timescale: 1)
        
        var ranges:[CMTimeRange] = []
        while position < duration
        {
            let available = duration - position
            let length = min(available, CUT_DURATION)
            
            let range = CMTimeRange(start: position, duration: length)
            position = position + length + CUT_INTERVAL
            ranges.append(range)
        }
        
        let editor = MovieEditor(transition: .RANDOM, transitionDuration: 1.0)
        if let exporter = editor.cut(asset: asset, with: ranges)
        {
            self.exporter = exporter
            let manager = FileManager.default
            outputURL = manager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("sample.mp4")
            if manager.fileExists(atPath: outputURL.path)
            {
                try? manager.removeItem(at: outputURL)
            }
            
            exporter.outputURL = outputURL
            Timer.scheduledTimer(timeInterval: 1/30, target: self, selector: #selector(progressUpdate(_:)), userInfo: nil, repeats: true)
            exporter.exportAsynchronously
            { [unowned self] in
                print("[EXPORT]", "done", exporter.status.description)
                
                DispatchQueue.main.async
                {
                    self.decodeMovie(url: self.outputURL)
                }
            }
            
            let press = UILongPressGestureRecognizer.init(target: self, action: #selector(pressUpdate(_:)))
            view.addGestureRecognizer(press)
        }
    }
    
    @objc func pressUpdate(_ guesture:UILongPressGestureRecognizer)
    {
        if guesture.state == .began
        {
            let share = UIActivityViewController(activityItems: [outputURL], applicationActivities: nil)
            self.present(share, animated: true, completion: nil)
        }
    }
    
    @objc func progressUpdate(_ timer:Timer)
    {
        progressView.progress = exporter.progress
        if exporter.progress == 1.0
        {
            progressView.isHidden = true
            timer.invalidate()
        }
    }
    
    func decodeMovie(url:URL)
    {
        let asset = AVAsset(url: url)
        let videoTrack = asset.tracks(withMediaType: .video)
        
        if let reader = try? AVAssetReader(asset: asset)
        {
            self.reader = reader
            let options:[CFString:Any] = [kCVPixelBufferPixelFormatTypeKey:kCVPixelFormatType_32BGRA]
            trackOutput = AVAssetReaderTrackOutput(track: videoTrack[0], outputSettings: options as [String : Any])
            trackOutput.alwaysCopiesSampleData = false
            reader.add(trackOutput)
            reader.startReading()
            
            Timer.scheduledTimer(timeInterval: 1/30, target: self, selector: #selector(readVideoSample(_:)), userInfo: nil, repeats: true)
        }
    }
    
    @objc func readVideoSample(_ timer:Timer)
    {
        if reader.status == .reading
        {
            background.async
            { [unowned self] in
                if let sample = self.trackOutput.copyNextSampleBuffer()
                {
                    if let cvImageBuffer = CMSampleBufferGetImageBuffer(sample)
                    {
                        let ciImage = CIImage(cvImageBuffer: cvImageBuffer)
                        DispatchQueue.main.async
                        {
                            self.viewport.image = UIImage(ciImage: ciImage)
                        }
                    }
                }
            }
        }
        else if reader.status == .completed
        {
            print("[PLAY]", "done")
            timer.invalidate()
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

