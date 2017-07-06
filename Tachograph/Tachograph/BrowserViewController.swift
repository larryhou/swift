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
    @IBOutlet var ib_name:UILabel!
    @IBOutlet var ib_id:UILabel!
    @IBOutlet var ib_timestamp:UILabel!
}

class BrowerViewController:UITableViewController, ModelObserver
{
    var OrientationContext:String?
    
    func model(assets: [CameraModel.CameraAsset], type: CameraModel.AssetType)
    {
        if type == .route && self.videoAssets.count != assets.count
        {
            loading = false
            
            videoAssets = assets
            tableView.reloadData()
            
            focusIndex = nil
            videoController?.player?.pause()
            videoController?.view.isHidden = true
        }
        
        loadingIndicator.stopAnimating()
        tableView.tableFooterView = nil
    }
    
    var videoAssets:[CameraModel.CameraAsset]!
    var formatter:DateFormatter!
    
    var loadingIndicator:UIActivityIndicatorView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        videoAssets = CameraModel.shared.routeVideos
        
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
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
            
            self.boundsVideo.size = sizeCell
            controller.view.frame = self.boundsVideo
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
    var focusIndex:IndexPath?, boundsVideo:CGRect!
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        focusIndex = indexPath
        
        tableView.beginUpdates()
        tableView.endUpdates()
        
        guard let url = URL(string: "http://172.20.10.3:8080/sample.mp4") else {return}
        
//        guard let data = assets?[indexPath.row] else { return }
//        guard let url = URL(string: data.url) else {return}
        
        if let cell = tableView.cellForRow(at: indexPath)
        {
            boundsVideo = cell.superview!.convert(cell.frame, to: self.view)
            boundsVideo.size.height = sizeCell.height
            
            if self.videoController == nil
            {
                videoController = AVPlayerViewController()
                videoController?.view.frame = boundsVideo
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
                self.videoController!.view.frame = self.boundsVideo
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
            cell.ib_name.text = data.name
            cell.ib_timestamp.text = formatter.string(from: data.timestamp)
            cell.ib_id.text = data.id
            return cell
        }
        
        return UITableViewCell()
    }
}
