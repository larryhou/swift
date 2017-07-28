//
//  BrowserViewController.swift
//  Tachograph
//
//  Created by larryhou on 4/7/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import AVKit

class AssetCell:UITableViewCell
{
    @IBOutlet var ib_image:UIImageView!
    @IBOutlet var ib_time:UILabel!
    @IBOutlet var ib_progress:UIProgressView!
    @IBOutlet var ib_id:UILabel!
    @IBOutlet var ib_share:UIButton!
    
    var data:CameraModel.CameraAsset?
}

class BrowerViewController:UIViewController, UITableViewDelegate, UITableViewDataSource,  ModelObserver
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var movieView: UIView!
    
    var videoAssets:[CameraModel.CameraAsset] = []
    var formatter:DateFormatter!
    
    var loadingIndicator:UIActivityIndicatorView!
    var playController:AVPlayerViewController!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        videoAssets = CameraModel.shared.routeVideos
        tableView.reloadData()
        
        formatter = DateFormatter()
        formatter.dateFormat = "HH:mm/MM-dd"
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loadingIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        loadingIndicator.hidesWhenStopped = false
        
        playController = AVPlayerViewController()
        playController.entersFullScreenWhenPlaybackBegins = true
        playController.exitsFullScreenWhenPlaybackEnds = true
        playController.view.frame = CGRect(origin: CGPoint(), size: movieView.frame.size)
        movieView.addSubview(playController.view)
    }
    
    func model(update: CameraModel.CameraAsset, type: CameraModel.AssetType)
    {
        
    }
    
    func model(assets: [CameraModel.CameraAsset], type: CameraModel.AssetType)
    {
        if type == .route && self.videoAssets.count != assets.count
        {
            loading = false
            videoAssets = assets
            guard let tableView = self.tableView else {return}
            tableView.reloadData()
        }
        
        guard let tableView = self.tableView else {return}
        loadingIndicator.stopAnimating()
        tableView.tableFooterView = nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 70
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return videoAssets.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        if indexPath.row == videoAssets.count - 1
        {
            if tableView.tableFooterView == nil
            {
                tableView.tableFooterView = loadingIndicator
            }
            
            loadingIndicator.startAnimating()
            
            loading = true
            CameraModel.shared.fetchRouteVideos()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let data = videoAssets[indexPath.row]
        guard let url = URL(string: data.url) else {return}
        
        if playController.player == nil
        {
            playController.player = AVPlayer(url: url)
        }
        else
        {
            playController.player?.replaceCurrentItem(with: AVPlayerItem(url: url))
        }
        
        playController.player?.play()
    }
    
    var loading = false
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AssetCell") as? AssetCell
        {
            let data = videoAssets[indexPath.row]
            cell.ib_time.text = formatter.string(from: data.timestamp)
            cell.ib_progress.isHidden = true
            cell.ib_progress.progress = 0.0
            cell.ib_id.text = data.id
            cell.data = data
            if let url = AssetManager.shared.get(cache: data.icon)
            {
                cell.ib_image.image = try! UIImage(data: Data(contentsOf: url))
            }
            else
            {
                cell.ib_image.image = UIImage(named: "icon.thm")
                AssetManager.shared.load(url: data.icon, completion:
                {
                    cell.ib_image.image = UIImage(data: $1)
                })
            }
            
            cell.ib_share.isHidden = !AssetManager.shared.has(cache: data.url)
            
            return cell
        }
        
        return UITableViewCell()
    }
}
