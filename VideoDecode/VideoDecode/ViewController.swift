//
//  ViewController.swift
//  MovieEditor
//
//  Created by larryhou on 03/01/2018.
//  Copyright © 2018 larryhou. All rights reserved.
//

import UIKit
import AVFoundation
import ReplayKit

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
    @IBOutlet weak var recordButton: UIButton!
    
    @IBOutlet weak var loopIndicator: UILabel!
    @IBOutlet weak var timeIndicator: UILabel!
    
    var trackOutput:AVAssetReaderTrackOutput!
    var reader:AVAssetReader!
    
    var exporter:AVAssetExportSession!
    
    var outputURL:URL!
    var formatter:DateFormatter!
    
    var playCount = 0
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        progressView.isHidden = true
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // Do any additional setup after loading the view, typically from a nib.
        guard let bundle = Bundle.main.path(forResource: "movie", ofType: "bundle") else {return}
        
        let location = URL(fileURLWithPath: "\(bundle)/funny.mp4")
        let layer = AVPlayerLayer(player: AVPlayer(url: location))
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.frame
        view.layer.insertSublayer(layer, at: 0)
        layer.player?.play()
        
        loopIndicator.text = String(format: "#%02d", playCount)
        layer.player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: .main, using:
        { (position) in
            if let duration = layer.player?.currentItem?.duration
            {
                if position == duration
                {
                    layer.player?.seek(to: kCMTimeZero)
                    layer.player?.play()
                    self.loopIndicator.text = String(format: "#%02d", self.playCount)
                }
            }
            
            self.timeIndicator.text = self.formatter.string(from: Date())
        })
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(stop(_:)))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
    }
    
    @IBAction func record(_ sender: UIButton)
    {
        recordButton.isHidden = true
        ScreenRecorder.shared.startRecording()
    }
    
    @IBAction func stop(_ sender: UITapGestureRecognizer)
    {
        guard sender.state == .recognized else { return }
        
        progressView.isHidden = false
        ScreenRecorder.shared.progressObserver = progressUpdate(_:)
        ScreenRecorder.shared.stopRecording(clipContext: "0-5;10-15")
        { (url, status) in
            print(status)
            self.recordButton.isHidden = false
            self.progressView.isHidden = true
        }
    }
    
    func progressUpdate(_ value:Float)
    {
        progressView.progress = value
    }
    
    override var prefersStatusBarHidden: Bool {return true}
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

