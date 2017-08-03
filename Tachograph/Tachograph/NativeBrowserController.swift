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

class NativeVideoController: AVPlayerViewController
{
    
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
            
            let asset = CameraModel.CameraAsset(id: id, name: name, url: url.path, icon: thumb, timestamp: timestamp!)
            assets.append(asset)
        }
        self.assets = assets
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
        let url = locations[indexPath.row]
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) as NSDictionary
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "NativeAssetCell") as? NativeAssetCell
        {
            let size = Double(attributes!.fileSize())
            
            cell.name.text = url.lastPathComponent
            cell.size.text = String.init(format: "%.3fM", size / 1024 / 1024)
            cell.thumb.image = try! UIImage(data: Data(contentsOf: url))
            return cell
        }
        
        return UITableViewCell()
    }
    
    //MARK: previewing
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        if let scroll = storyboard?.instantiateViewController(withIdentifier: "ImageScrollController") as? ImageScrollController
        {
            scroll.imageAssets = assets
            scroll.index = (viewControllerToCommit as! ImagePeekController).index
            show(scroll, sender: self)
        }
    }
    
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
            return peek
        }
        
        return nil
    }
}

class NativeScrollController:UIPageViewController, UIPageViewControllerDataSource
{
    var nativeControllers:[UIViewController]!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.dataSource = self
        
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
}
