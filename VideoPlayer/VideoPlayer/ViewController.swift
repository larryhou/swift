//
//  ViewController.swift
//  VideoPlayer
//
//  Created by larryhou on 4/14/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation

extension CMTime:Printable
{
	public var description:String
	{
		return "{value:\(value), timescale:\(timescale)}"
	}
}

extension AVKeyValueStatus
{
	var description:String
	{
		switch self
		{
			case .Loaded:return "Loaded"
			case .Loading:return "Loading"
			case .Failed:return "Failed"
			case .Cancelled:return "Cancelled"
			case .Unknown:return "Unknown"
		}
	}
}

extension AVPlayerItemStatus
{
	var description:String
	{
		switch self
		{
			case .Unknown:return "Unknown"
			case .ReadyToPlay:return "ReadyToPlay"
			case .Failed:return "Failed"
		}
	}
}

class ViewController: UIViewController, AVAssetResourceLoaderDelegate
{
	private var ItemStatusContext:String?
	
	private var player:AVPlayer!
	private var playerView:AVPlayerLayer!

	@IBOutlet weak var indicator: UIProgressView!
	private var duration:CMTime!
	
	private var isComplete:Bool = false
	private var pan:UIPanGestureRecognizer!
	
	private var origin:CGPoint!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		let url = NSURL(string: "http://10.64.200.54/videos/01.mp4")!
		self.title = url.absoluteString
		
		let asset = AVURLAsset(URL: url, options: nil)
		asset.resourceLoader.setDelegate(self, queue: dispatch_get_main_queue())
		asset.loadValuesAsynchronouslyForKeys(["duration"])
		{
			println("duration:" + asset.duration.description)
			self.duration = asset.duration
		}
		
		let playerItem  = AVPlayerItem(asset: asset)
		playerItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: &ItemStatusContext)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "playDidReachEnd:", name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
		
		player = AVPlayer(playerItem: playerItem)
		player.addPeriodicTimeObserverForInterval(CMTimeMake(10, 1000), queue: dispatch_get_main_queue())
		{ (time:CMTime) in
			self.updateIndicator(time)
		}
		
		playerView = AVPlayerLayer(player: player)
		playerView.backgroundColor = UIColor.blackColor().CGColor
		playerView.videoGravity = AVLayerVideoGravityResizeAspect
		playerView.frame = view.frame
		
		view.layer.insertSublayer(playerView, below: indicator.layer)
		indicator.progress = 0.0
		
		setupGuestures()
	}
	
	//MARK: guestures
	func setupGuestures()
	{
		pan = UIPanGestureRecognizer()
		pan.addTarget(self, action: "panGuestureChanged:")
		view.addGestureRecognizer(pan)
		pan.enabled = false
	}
	
	func panGuestureChanged(guesture:UIPanGestureRecognizer)
	{
		println(guesture)
		switch guesture.state
		{
			case .Began:
				origin = guesture.locationInView(view)
				break
			
			case .Ended:
				origin = nil
				break
			
			case .Changed:
				let point = guesture.locationInView(view)
				var rate = CGFloat(player.rate) + 2 * (point.x - origin.x) / view.frame.width
				player.rate = Float(rate)
				break
				
			default:break
		}
	}
	
	//MARK: indicator
	func updateIndicator(time:CMTime)
	{
		let tick = Double(time.value) / Double(time.timescale)
		let total = Double(duration.value) / Double(duration.timescale)
		
		indicator.progress = Float(tick) / Float(total)
	}
	
	func playDidReachEnd(sender:AVPlayerItem)
	{
		isComplete = true
	}
	
	func pause()
	{
		player.pause()
	}
	
	func play()
	{
		if isComplete
		{
			player.seekToTime(kCMTimeZero)
			indicator.progress = 0
		}
		
		player.play()
	}
	
	override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>)
	{
		if context == &ItemStatusContext
		{
			let playerItem = object as! AVPlayerItem
			println(playerItem.status.description)
			
			if playerItem.status == AVPlayerItemStatus.ReadyToPlay
			{
				describeVideo(playerItem)
				isComplete = false
				pan.enabled = true
				
				player.play()
			}
		}
	}
	
	func describeVideo(item:AVPlayerItem)
	{
		println(item.tracks)
		println("canPlayerFastForward: \(item.canPlayFastForward)")
		println("canPlayFastReverse: \(item.canPlayFastReverse)")
		println("canPlaySlowForward: \(item.canPlaySlowForward)")
		println("canPlaySlowReverse: \(item.canPlaySlowReverse)")
	}
	
	//MARK: rotation
	override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
	{
		playerView.frame = CGRectMake(0, 0, size.width, size.height)
	}
	
	//MARK: AVAssetResourceLoaderDelegate
	func resourceLoader(resourceLoader: AVAssetResourceLoader!, shouldWaitForResponseToAuthenticationChallenge authenticationChallenge: NSURLAuthenticationChallenge!) -> Bool
	{
		let protectionSpace = authenticationChallenge.protectionSpace
		
		println(protectionSpace.authenticationMethod!)
		if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
		{
			let credential = NSURLCredential(forTrust: protectionSpace.serverTrust)
			authenticationChallenge.sender.useCredential(credential, forAuthenticationChallenge: authenticationChallenge)
			authenticationChallenge.sender.continueWithoutCredentialForAuthenticationChallenge(authenticationChallenge)
		}
		
		return true
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
}

