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
}

class BrowerViewController:UITableViewController, UITableViewDataSourcePrefetching,  ModelObserver
{
    var OrientationContext:String?
    
    func model(assets: [CameraModel.CameraAsset], type: CameraModel.AssetType)
    {
        if type == .route && self.videoAssets.count != assets.count
        {
            loading = false
            if let index = self.focusIndex
            {
                let data = videoAssets[index.row]
                for i in 0..<assets.count
                {
                    if assets[i].name == data.name
                    {
                        self.focusIndex = IndexPath(row: i, section: index.section)
                    }
                }
            }
            
            videoAssets = assets
            tableView.reloadData()
            
            if let index = self.focusIndex
            {
                if let cell = tableView.cellForRow(at: index)
                {
                    var frame = cell.superview!.convert(cell.frame, to: view)
                    frame.size.height = sizeCell.height
                    UIView.animate(withDuration: 0.25)
                    {
                        self.videoController?.view.frame = frame
                    }
                } 
            }
        }
        
        loadingIndicator.stopAnimating()
        tableView.tableFooterView = nil
    }
    
    var videoAssets:[CameraModel.CameraAsset] = []
    var formatter:DateFormatter!
    
    var loadingIndicator:UIActivityIndicatorView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        videoAssets = CameraModel.shared.routeVideos
        
        formatter = DateFormatter()
        formatter.dateFormat = "HH:mm MM-dd"
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationUpdate), name: .UIDeviceOrientationDidChange, object: nil)
        
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loadingIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        loadingIndicator.hidesWhenStopped = false
    }
    
    var sizeCell:CGSize = CGSize()
    @objc func orientationUpdate()
    {
        sizeCell = CGSize(width: view.frame.width, height: view.frame.width / 16 * 9)
        if let controller = self.videoController
        {
            tableView.beginUpdates()
            tableView.endUpdates()
            
            let barController = self.parent as! UITabBarController
            
            self.frameVideo.size = sizeCell
            controller.view.frame = self.frameVideo
            let orientation = UIDevice.current.orientation
            if orientation == .landscapeRight || orientation == .landscapeLeft
            {
                if let index = self.focusIndex
                {
                    tableView.scrollToRow(at: index, at: .top, animated: true)
                }
                
                barController.tabBar.isHidden = true
            }
            else
            {
                barController.tabBar.isHidden = false
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath])
    {
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if focusIndex == indexPath
        {
            return sizeCell.height
        }
        
        return 70
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return videoAssets.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
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
    
    var videoController:AVPlayerViewController?
    var focusIndex:IndexPath?, frameVideo:CGRect!
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        focusIndex = indexPath
        
        tableView.beginUpdates()
        tableView.endUpdates()
        
        guard let url = URL(string: "http://10.65.133.85:8080/sample.mp4") else {return}
        
//        let data = videoAssets[indexPath.row]
//        guard let url = URL(string: data.url) else {return}
        
        if let cell = tableView.cellForRow(at: indexPath)
        {
            frameVideo = cell.superview!.convert(cell.frame, to: self.view)
            frameVideo.size.height = sizeCell.height
            
            if self.videoController == nil
            {
                videoController = AVPlayerViewController()
                videoController?.view.frame = frameVideo
                view.addSubview(videoController!.view)
                videoController?.view.isHidden = true
            }
            else
            {
                videoController?.player?.pause()
            }
            
            UIView.setAnimationCurve(.easeInOut)
            UIView.animate(withDuration: 0.25, animations:
            { [unowned self] in
                self.videoController!.view.isHidden = false
                self.videoController!.view.frame = self.frameVideo
            }, completion:
            { [unowned self] (flag) in
                self.videoController!.player = AVPlayer(url: url)
                self.videoController!.player?.automaticallyWaitsToMinimizeStalling = false
            })
        }
    }
    
    var loading = false
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AssetCell") as? AssetCell
        {
            let data = videoAssets[indexPath.row]
            cell.ib_time.text = formatter.string(from: data.timestamp)
            cell.ib_progress.isHidden = true
            cell.ib_id.text = data.id
            return cell
        }
        
        return UITableViewCell()
    }
}
