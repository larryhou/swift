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

class AssetCell:UITableViewCell
{
    @IBOutlet var ib_name:UILabel!
    @IBOutlet var ib_id:UILabel!
    @IBOutlet var ib_timestamp:UILabel!
}

class BrowerViewController:UITableViewController, ModelObserver
{
    func model(assets: [CameraModel.CameraAsset], type: CameraModel.AssetType)
    {
        if type == .route
        {
            self.assets = assets
            self.tableView.reloadData()
        }
    }
    
    var assets:[CameraModel.CameraAsset]!
    var formatter:DateFormatter!
    var focusHeight:CGFloat = 0
    
    var videoController:AVPlayer!
    var videoLayer:AVPlayerLayer!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        assets = CameraModel.shared.routeVideos
        
        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        focusHeight = view.frame.width / 16 * 9
        
        videoController = AVPlayer()
        videoController.actionAtItemEnd = .none
        
        videoLayer = AVPlayerLayer(player: videoController)
        videoLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(videoLayer)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if focusIndex == indexPath
        {
            return focusHeight
        }
        
        return 70
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return assets.count
    }
    
    var focusIndex:IndexPath?, focusBounds:CGRect!
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        focusIndex = indexPath
        
        tableView.beginUpdates()
        tableView.endUpdates()
        
        guard let url = URL(string: "http://10.65.133.85/sample.mp4") else {return}
        
        let asset = AVAsset(url: url)
        videoController.replaceCurrentItem(with: AVPlayerItem(asset: asset))
        if let cell = tableView.cellForRow(at: indexPath)
        {
            let point = cell.convert(cell.frame.origin, to: self.view)
            focusBounds = CGRect(origin: point, size: CGSize(width: view.frame.width, height: focusHeight))
            videoLayer.bounds = focusBounds
        }
        videoController.play()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AssetCell") as? AssetCell
        {
            let data = assets[indexPath.row]
            cell.ib_name.text = data.name
            cell.ib_timestamp.text = formatter.string(from: data.timestamp)
            cell.ib_id.text = data.id
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        focusHeight = size.width / 16 * 9
        let orientation = UIDevice.current.orientation
        if orientation == .landscapeLeft || orientation == .landscapeRight
        {
            videoLayer.bounds = CGRect(origin: CGPoint(), size: size)
        }
        else
        {
            videoLayer.bounds = focusBounds
        }
    }
}
