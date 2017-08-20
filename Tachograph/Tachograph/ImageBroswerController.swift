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

class AssetCollectionFlowLayout:UICollectionViewFlowLayout
{
    var spacing:CGFloat = 1
    func setup(containerWidth width:CGFloat, column:Int, margin:CGFloat, cellAspect ratio:CGFloat = 0.75)
    {
        let column = CGFloat(column)
        let cellWidth = floor((width - (column + 1) * margin)/column)
        let spacing = (width - column * cellWidth)/(column + 1)
        self.minimumLineSpacing = spacing
        self.minimumInteritemSpacing = spacing
        self.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        self.itemSize = CGSize(width: cellWidth, height: cellWidth * ratio)
        self.spacing = spacing
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]?
    {
        if var elements = super.layoutAttributesForElements(in: rect)
        {
            for i in 1..<elements.count
            {
                let item = elements[i]
                let prev = elements[i - 1]
                
                let start = prev.frame.maxX
                if start + spacing + item.frame.size.width < collectionViewContentSize.width
                {
                    var frame = item.frame
                    frame.origin.x = start + spacing
                    item.frame = frame
                }
            }
            
            return elements
        }
        
        return nil
    }
}

extension ImageBrowserController:UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return layout.itemSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    {
        return layout.sectionInset
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return layout.spacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    {
        return layout.spacing
    }
}

class ImageBrowserController:UICollectionViewController,UIViewControllerPreviewingDelegate, CameraModelDelegate
{
    var takenImages:[CameraModel.CameraAsset] = []
    
    private var column = 3
    private var layout:AssetCollectionFlowLayout!
    
    override var collectionViewLayout: UICollectionViewLayout
    {
        if layout == nil
        {
            layout = AssetCollectionFlowLayout()
        }
        return layout
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        collectionView?.allowsSelection = true
        registerForPreviewing(with: self, sourceView: view)
        
        column = 2
        if let layout = collectionViewLayout as? AssetCollectionFlowLayout
        {
            layout.setup(containerWidth: view.frame.width, column: column, margin: 1)
        }
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
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    //MARK: data
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
            scroll.pageAssets = takenImages
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
                peek.index = index.row
                peek.preferredContentSize = CGSize(width: size.width, height: size.width/16*9)
                peek.presentController = self
                return peek
            }
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        if let scroll = storyboard?.instantiateViewController(withIdentifier: "ImageScrollController") as? ImageScrollController
        {
            scroll.index = (viewControllerToCommit as! ImagePeekController).index
            scroll.pageAssets = takenImages
            show(scroll, sender: self)
        }
    }
}
