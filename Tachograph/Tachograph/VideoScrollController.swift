//
//  VideoScrollController.swift
//  Tachograph
//
//  Created by larryhou on 04/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class VideoPlayController: AVPlayerViewController, PageProtocol
{
    var PlayerStatusContext:String?
    static func instantiate(_ storyboard: UIStoryboard) -> PageProtocol
    {
        return storyboard.instantiateViewController(withIdentifier: "VideoPlayController") as! PageProtocol
    }
    
    var pageAsset: Any?
    {
        didSet
        {
            if let data = self.pageAsset as? CameraModel.CameraAsset
            {
                self.url = data.url
            }
        }
    }
    
    var index:Int = -1
    var url:String?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.player = AVPlayer()
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchUpdate(sender:)))
        view.addGestureRecognizer(pinch)
        
        let press = UILongPressGestureRecognizer(target: self, action: #selector(pressUpdate(sender:)))
        view.addGestureRecognizer(press)
    }
    
    @objc func pressUpdate(sender:UILongPressGestureRecognizer)
    {
        if sender.state != .began {return}
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "保存到相册", style: .default, handler:{ _ in self.saveToAlbum() }))
        alertController.addAction(UIAlertAction(title: "分享", style: .default, handler:{ _ in self.share() }))
        alertController.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func saveToAlbum()
    {
        guard let url = self.url else {return}
        UISaveVideoAtPathToSavedPhotosAlbum(url, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func video(_ videoPath:String, didFinishSavingWithError error:NSError?, contextInfo context:Any?)
    {
        var message:String?
        
        let title:String
        if error == nil
        {
            title = "视频保存成功"
        }
        else
        {
            title = "视频保存失败"
            message = error.debugDescription
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "知道了", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func share()
    {
        guard let url = self.url else {return}
        if let location = AssetManager.shared.get(cache: url)
        {
            let controller = UIActivityViewController(activityItems: [location], applicationActivities: nil)
            present(controller, animated: true, completion: nil)
        }
    }
    
    @objc func pinchUpdate(sender:UIPinchGestureRecognizer)
    {
        if sender.state == .changed
        {
            if sender.scale <= 0.5
            {
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        self.player?.pause()
        
        if let identifier = self.observerIdentifier
        {
            self.player?.removeTimeObserver(identifier)
            self.observerIdentifier = nil
        }
    }
    
    var lastUrl:String?
    var observerIdentifier:Any?
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        guard let player = self.player else {return}
        
        guard let url = self.url else
        {
            player.pause()
            player.replaceCurrentItem(with: nil)
            return
        }
        
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        observerIdentifier = player.addPeriodicTimeObserver(forInterval: interval, queue: .main)
        {
            if let duration = player.currentItem?.duration, $0 >= duration
            {
                self.play(from:0)
            }
        }
        
        if lastUrl == url {return}
        
        let item:AVPlayerItem
        if url.hasPrefix("http")
        {
            item = AVPlayerItem(url: URL(string: url)!)
        }
        else
        {
            item = AVPlayerItem(url: URL(fileURLWithPath: url))
        }
        
        player.replaceCurrentItem(with: item)
        lastUrl = url
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        self.player?.play()
    }
    
    func play(from position:Double = 0)
    {
        guard let player = self.player else {return}
        
        let position = CMTime(seconds: position, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: position)
        player.play()
    }
}

class VideoScrollController: PageController<VideoPlayController, CameraModel.CameraAsset>
{
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        UIViewPropertyAnimator.init(duration: 0.25, dampingRatio: 1.0)
        {
            self.navigationController?.navigationBar.alpha = 0
        }.startAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        UIViewPropertyAnimator.init(duration: 0.25, dampingRatio: 1.0)
        {
            self.navigationController?.navigationBar.alpha = 1
        }.startAnimation()
    }
}
