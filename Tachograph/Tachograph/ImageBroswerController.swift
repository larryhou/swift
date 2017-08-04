//
//  ImageBroswerController.swift
//  Tachograph
//
//  Created by larryhou on 31/07/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit

class ImageCell:UICollectionViewCell
{
    @IBOutlet weak var ib_image:UIImageView!
}

class ImageBrowserController:UICollectionViewController, UICollectionViewDelegateFlowLayout,UIViewControllerPreviewingDelegate, CameraModelDelegate
{
    var takenImages:[CameraModel.CameraAsset] = []
    private var size = CGSize()
    private var insets = UIEdgeInsets()
    private var column = 3
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        collectionView?.allowsSelection = true
        registerForPreviewing(with: self, sourceView: view)
        
        let fit = fitsize(length: view.frame.width)
        size = CGSize(width: fit.0, height: fit.0/4*3)
        insets = UIEdgeInsets(top: fit.1, left: fit.1, bottom: fit.1, right: fit.1)
        column = fit.2
    }
    
    func fitsize(length:CGFloat, column:CGFloat = 2, margin:CGFloat = 10, limitWidth:CGFloat = 120, limitMargin:CGFloat = 20)->(CGFloat, CGFloat, Int)
    {
        var margin = margin
        var width = (length - (column + 1) * margin)/column
        if width > limitWidth
        {
            width = limitWidth
            let remain = length - column * width - margin * (column + 1)
            if remain > width
            {
                return fitsize(length: length, column: column + 1, margin: margin)
            }
            else
            {
                let gap = (length - column * width)/(column + 1)
                if gap > limitMargin
                {
                    return fitsize(length: length, column: column + 1, margin: margin)
                }
                
                margin = gap
            }
        }
        
        return (width, margin, Int(column))
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        CameraModel.shared.delegate = self
        loadModel()
    }
    
    func loadModel()
    {
        CameraModel.shared.fetchImages()
    }
    
    func model(assets: [CameraModel.CameraAsset], type: CameraModel.AssetType)
    {
        if type != .image {return}
        takenImages = assets
        collectionView?.reloadData()
    }
    
    func model(update: CameraModel.CameraAsset, type: CameraModel.AssetType)
    {
        takenImages.insert(update, at: 0)
        let index = IndexPath(row: 0, section: 0)
        collectionView?.insertItems(at: [index])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return self.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    {
        return self.insets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return self.insets.bottom
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return takenImages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let data = takenImages[indexPath.row]
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCell
        {
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
            return cell
        }
        return UICollectionViewCell()
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        let max = takenImages.count / column
        if (indexPath.row + 1) / column == max
        {
            loadModel()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        if let scroll = storyboard?.instantiateViewController(withIdentifier: "ImageScrollController") as? ImageScrollController
        {
            scroll.index = indexPath.row
            scroll.imageAssets = takenImages
            show(scroll, sender: self)
        }
    }
    
    //MARK: 3d-touch
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        if let index = collectionView?.indexPathForItem(at: location)
        {
            if let cell = collectionView?.cellForItem(at: index)
            {
                previewingContext.sourceRect = cell.superview!.convert(cell.frame, to: view)
            }
            
            let data = takenImages[index.row]
            if let peek = storyboard?.instantiateViewController(withIdentifier: "ImagePeekController") as? ImagePeekController
            {
                peek.url = data.url
                let size = view.frame.size
                peek.preferredContentSize = CGSize(width: size.width, height: size.width/16*9)
                return peek
            }
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        if let preview = storyboard?.instantiateViewController(withIdentifier: "ImagePreviewController") as? ImagePreviewController
        {
            preview.url = (viewControllerToCommit as! ImagePeekController).url
            show(preview, sender: self)
        }
    }
}
