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
    @IBOutlet weak var ib_image:UIImageView!
    @IBOutlet weak var ib_time:UILabel!
    @IBOutlet weak var ib_progress:UIProgressView!
    @IBOutlet weak var ib_id:UILabel!
    @IBOutlet weak var ib_share:UIButton!
    @IBOutlet weak var ib_download: UIButton!
    
    var data:CameraModel.CameraAsset?
    
    func progress(name:String, value:Float)
    {
        if value < 1.0 || Float.nan == value
        {
            ib_share.isHidden = true
        }
        else
        {
            ib_share.isHidden = false
        }
        
        ib_progress.progress = value
        
        ib_download.isHidden = !ib_share.isHidden
        ib_progress.isHidden = ib_download.isHidden
    }
}

class EventBrowserController:RouteBrowerController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        assetType = .event
    }
    
    override func loadModel()
    {
        loading = true
        CameraModel.shared.fetchEventVideos()
    }
}

class RouteBrowerController:UIViewController, UITableViewDelegate, UITableViewDataSource, CameraModelDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var movieView: UIView!
    
    var videoAssets:[CameraModel.CameraAsset] = []
    var formatter:DateFormatter!
    
    var loadingIndicator:UIActivityIndicatorView!
    var playController:AVPlayerViewController!
    var assetType:CameraModel.AssetType = .route
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        formatter = DateFormatter()
        formatter.dateFormat = "HH:mm/MM-dd"
        loadViews()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        loadModel()
        CameraModel.shared.delegate = self
    }
    
    func loadModel()
    {
        loading = true
        CameraModel.shared.fetchRouteVideos()
    }
    
    func loadViews()
    {
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loadingIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        loadingIndicator.hidesWhenStopped = false
        
        playController = AVPlayerViewController()
        playController.entersFullScreenWhenPlaybackBegins = true
        playController.view.frame = CGRect(origin: CGPoint(), size: movieView.frame.size)
        movieView.addSubview(playController.view)
    }
    
    func model(update: CameraModel.CameraAsset, type: CameraModel.AssetType)
    {
        if type != assetType {return}
        videoAssets.insert(update, at: 0)
        
        let index = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [index], with: UITableViewRowAnimation.top)
    }
    
    func model(assets: [CameraModel.CameraAsset], type: CameraModel.AssetType)
    {
        if self.videoAssets.count != assets.count
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
    
    //MARK: cell
    @IBAction func share(_ sender: UIButton)
    {
        let rect = sender.superview!.convert(sender.frame, to: tableView)
        if let list = tableView.indexPathsForRows(in: rect)
        {
            let data = videoAssets[list[0].row]
            if let location = AssetManager.shared.get(cache: data.url)
            {
                let controller = UIActivityViewController(activityItems: [location], applicationActivities:nil)
                present(controller, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func download(_ sender: UIButton)
    {
        let rect = sender.superview!.convert(sender.frame, to: tableView)
        if let list = tableView.indexPathsForRows(in: rect)
        {
            let index = list[0]
            if let cell = tableView.cellForRow(at: index) as? AssetCell
            {
                let data = videoAssets[index.row]
                AssetManager.shared.load(url: data.url, completion: nil, progression: cell.progress(name:value:))
            }
        }
    }
    
    //MARK: table
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
            loadModel()
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
            cell.ib_download.isHidden = !cell.ib_share.isHidden
            return cell
        }
        
        return UITableViewCell()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {return .portrait}
}
