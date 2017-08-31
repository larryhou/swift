//
//  NativeBrowserController.swift
//  Tachograph
//
//  Created by larryhou on 03/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class NativeAssetCell:UITableViewCell
{
    @IBOutlet weak var thumb:UIImageView!
    @IBOutlet weak var name:UILabel!
    @IBOutlet weak var size:UILabel!
}

class NativeBrowserController: UITableViewController, UIViewControllerPreviewingDelegate
{
    var isVideo = false
    var locations:[URL] = []
    var assets:[CameraModel.CameraAsset] = []
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.registerForPreviewing(with: self, sourceView: view)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        var assets:[CameraModel.CameraAsset] = []
        locations = AssetManager.shared.fetchAssets(suffix: isVideo ? "mp4" : "jpg")
        for url in locations
        {
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) as NSDictionary
            let id = attributes!.fileSize().description
            let name = url.lastPathComponent
            let timestamp = attributes!.fileCreationDate()
            let thumb = String(name.split(separator: ".").first!) + ".thm"
            
            var asset = CameraModel.CameraAsset(id: id, name: name, url: url.path, icon: thumb, timestamp: timestamp!)
            asset.info = CameraModel.NativeAssetInfo(location: url, size: attributes!.fileSize())
            assets.append(asset)
        }
        self.assets = assets.reversed()
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return assets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let data = assets[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "NativeAssetCell") as? NativeAssetCell
        {
            let size = Double(data.info!.size)
            
            cell.name.text = data.name
            cell.size.text = String(format: "%.3fM", size / 1024 / 1024)
            
            cell.thumb.image = nil
            if let thumb = AssetManager.shared.get(cacheOf: data.icon)
            {
                cell.thumb.image = try! UIImage(data: Data(contentsOf: thumb))
            }
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        if isVideo
        {
            if let scroll = storyboard?.instantiateViewController(withIdentifier: "VideoScrollController") as? VideoScrollController
            {
                scroll.pageAssets = assets
                scroll.index = indexPath.row
                present(scroll, animated: true, completion: nil)
            }
        }
        else
        {
            if let scroll = storyboard?.instantiateViewController(withIdentifier: "ImageScrollController") as? ImageScrollController
            {
                scroll.pageAssets = assets
                scroll.index = indexPath.row
                present(scroll, animated: true, completion: nil)
            }
        }
    }
    
    //MARK: previewing
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        guard let index = tableView.indexPathForRow(at: location), !isVideo else {return nil}
        if let cell = tableView.cellForRow(at: index)
        {
            previewingContext.sourceRect = cell.superview!.convert(cell.frame, to: view)
        }
        
        let data = assets[index.row]
        if let peek = storyboard?.instantiateViewController(withIdentifier: "ImagePeekController") as? ImagePeekController
        {
            peek.index = index.row
            peek.url = data.url
            
            let size = view.frame.size
            peek.preferredContentSize = CGSize(width: size.width, height: size.width/16*9)
            peek.presentController = self
            return peek
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        if let scroll = storyboard?.instantiateViewController(withIdentifier: "ImageScrollController") as? ImageScrollController
        {
            scroll.pageAssets = assets
            scroll.index = (viewControllerToCommit as! ImagePeekController).index
            present(scroll, animated: true, completion: nil)
        }
    }
}

class NativeScrollController:UIPageViewController, UIPageViewControllerDataSource
{
    var nativeControllers:[UIViewController]!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        dataSource = self
        nativeControllers = []
        
        var controller = storyboard?.instantiateViewController(withIdentifier: "NativeBrowserController") as! NativeBrowserController
        controller.isVideo = false
        nativeControllers.append(controller)
        setViewControllers([controller], direction: .forward, animated: false, completion: nil)
        controller = storyboard?.instantiateViewController(withIdentifier: "NativeBrowserController") as! NativeBrowserController
        controller.isVideo = true
        nativeControllers.append(controller)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        if viewController == nativeControllers[0]
        {
            return nativeControllers[1]
        }
        else
        {
            return nativeControllers[0]
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        if viewController == nativeControllers[0]
        {
            return nativeControllers[1]
        }
        else
        {
            return nativeControllers[0]
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {return .portrait}
}
