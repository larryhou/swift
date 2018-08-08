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

class VideoPlayController: AVPlayerViewController, PageProtocol {
    var PlayerStatusContext: String?
    static func instantiate(_ storyboard: UIStoryboard) -> PageProtocol {
        return storyboard.instantiateViewController(withIdentifier: "VideoPlayController") as! PageProtocol
    }

    var pageAsset: Any? {
        didSet {
            if let data = self.pageAsset as? CameraModel.CameraAsset {
                self.url = data.url
            }
        }
    }

    var index: Int = -1
    var url: String?
    override func viewDidLoad() {
        super.viewDidLoad()

        self.player = AVPlayer()

        let press = UILongPressGestureRecognizer(target: self, action: #selector(pressUpdate(sender:)))
        view.addGestureRecognizer(press)
    }

    @objc func pressUpdate(sender: UILongPressGestureRecognizer) {
        if sender.state != .began {return}
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "保存到相册", style: .default, handler: { _ in self.saveToAlbum() }))
        alertController.addAction(UIAlertAction(title: "分享", style: .default, handler: { _ in self.share() }))
        alertController.addAction(UIAlertAction(title: "删除", style: .destructive, handler: { _ in self.delete() }))
        alertController.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    func delete() {
        guard let url = self.url else {return}
        dismiss(animated: true) {
            let success = AssetManager.shared.remove(url)
            AlertManager.show(title: success ? "文件删除成功" : "文件删除失败", message: url, sender: self)
        }
    }

    func saveToAlbum() {
        guard let url = self.url else {return}
        UISaveVideoAtPathToSavedPhotosAlbum(url, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func video(_ videoPath: String, didFinishSavingWithError error: NSError?, contextInfo context: Any?) {
        AlertManager.show(title: error == nil ? "视频保存成功" : "视频保存失败", message: error?.debugDescription, sender: self)
    }

    func share() {
        guard let url = self.url else {return}
        if let location = AssetManager.shared.get(cacheOf: url) {
            let controller = UIActivityViewController(activityItems: [location], applicationActivities: nil)
            present(controller, animated: true, completion: nil)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player?.pause()

        if let identifier = self.observerIdentifier {
            self.player?.removeTimeObserver(identifier)
            self.observerIdentifier = nil
        }
    }

    var lastUrl: String?
    var observerIdentifier: Any?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let player = self.player else {return}

        guard let url = self.url else {
            player.pause()
            player.replaceCurrentItem(with: nil)
            return
        }

        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        observerIdentifier = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
            if let duration = player.currentItem?.duration, $0 >= duration {
                self.play(from: 0)
            }
        }

        if lastUrl == url { return }

        let item: AVPlayerItem
        if url.hasPrefix("http") {
            item = AVPlayerItem(url: URL(string: url)!)
        } else {
            item = AVPlayerItem(url: URL(fileURLWithPath: url))
        }

        player.replaceCurrentItem(with: item)

        lastUrl = url
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.player?.play()
    }

    func play(from position: Double = 0) {
        guard let player = self.player else {return}

        let position = CMTime(seconds: position, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: position)
        player.play()
    }
}

class VideoScrollController: PageController<VideoPlayController, CameraModel.CameraAsset>, UIGestureRecognizerDelegate {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIViewPropertyAnimator.init(duration: 0.25, dampingRatio: 1.0) {
            self.navigationController?.navigationBar.alpha = 0
        }.startAnimation()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(panUpdate(sender:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return UIDevice.current.orientation.isPortrait
    }

    var fractionComplete = CGFloat.nan
    var dismissAnimator: UIViewPropertyAnimator!
    @objc func panUpdate(sender: UIPanGestureRecognizer) {
        switch sender.state {
            case .began:
                dismissAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .linear) { [unowned self] in
                    self.view.frame.origin.y = self.view.frame.height
                }
                dismissAnimator.addCompletion { [unowned self] position in
                    if position == .end {
                        self.dismiss(animated: false, completion: nil)
                    }
                    self.fractionComplete = CGFloat.nan
                }
                dismissAnimator.pauseAnimation()
            case .changed:
                if fractionComplete.isNaN {fractionComplete = 0}

                let translation = sender.translation(in: view)
                fractionComplete += translation.y / view.frame.height
                fractionComplete = min(1, max(0, fractionComplete))
                dismissAnimator.fractionComplete = fractionComplete
                sender.setTranslation(CGPoint.zero, in: view)
            default:
                if dismissAnimator.fractionComplete <= 0.25 {
                    dismissAnimator.isReversed = true
                }
                dismissAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 1.0)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIViewPropertyAnimator.init(duration: 0.25, dampingRatio: 1.0) {
            self.navigationController?.navigationBar.alpha = 1
        }.startAnimation()
    }
}
