//
//  ImagePickViewController.swift
//  VisionPower
//
//  Created by larryhou on 15/09/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import Photos
import UIKit

class PhotoCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    var requestID: PHImageRequestID = -1
}

class AlbumPreviewViewLayout: UICollectionViewFlowLayout {
    var grid:(size: CGFloat, spacing: CGFloat, column: Int) = (CGFloat.nan, CGFloat.nan, 0)

    private func fitgrid(dimension: CGFloat,
                 rangeSize:(min: CGFloat, max: CGFloat) = (50, 100),
              rangeSpacing:(min: CGFloat, max: CGFloat) = (1, 5)) -> (size: CGFloat, spacing: CGFloat, column: Int) {
        var size = rangeSize.max
        var spacing = rangeSpacing.min
        while true {
            let num = floor(dimension / size)
            let remain = dimension - num * size - (num + 1) * spacing
            if  remain < 0 {
                size -= 1
            } else if remain > 0 {
                let value = (dimension - num * size) / (num + 1)
                if value < rangeSpacing.max {
                    spacing = value
                    break
                }

                size -= 1
            } else {
                break
            }
        }

        let column = (dimension - spacing) / (spacing + size)
        return (size, spacing, Int(column))
    }

    override func prepare() {
        super.prepare()

        grid = fitgrid(dimension: collectionView!.frame.width)
        print("grid", grid)

        self.itemSize = CGSize(width: grid.size, height: grid.size)
        self.sectionInset = UIEdgeInsets(top: grid.spacing, left: grid.spacing, bottom: grid.spacing, right: grid.spacing)
        self.minimumInteritemSpacing = 0
        self.minimumLineSpacing = grid.spacing
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if var elements = super.layoutAttributesForElements(in: rect), elements.count >= 1 {
            for i in 1..<elements.count {
                let item = elements[i]
                let prev = elements[i - 1]

                let start = prev.frame.maxX
                if start + grid.spacing + item.frame.size.width < collectionViewContentSize.width {
                    var frame = item.frame
                    frame.origin.x = start + grid.spacing
                    item.frame = frame
                }
            }

            return elements
        }

        return nil
    }
}

protocol PhotoSelectViewControllerDelegate {
    func didSelectPhoto(_ asset: PHAsset)
}

class PhotoSelectViewController: UIViewController {
    private static var shared: PhotoSelectViewController!
    public static func instantiate(from storyboard: UIStoryboard, delegate: PhotoSelectViewControllerDelegate? = nil) -> PhotoSelectViewController {
        if shared == nil {
            shared = (storyboard.instantiateViewController(withIdentifier: "PhotoSelectViewController") as? PhotoSelectViewController)!
            shared.delegate = delegate
        }
        return shared
    }

    var assets: [PHAsset] = []
    var imageManager: PHCachingImageManager!

    var delegate: PhotoSelectViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        imageManager = PHCachingImageManager()

        let fetchOptions = PHFetchOptions()
        fetchOptions.includeAssetSourceTypes = .typeUserLibrary
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeAllBurstAssets = false

        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        for n in 0..<result.count {
            assets.append(result.object(at: n))
        }

        let cachingOptions = PHImageRequestOptions()
        cachingOptions.deliveryMode = .fastFormat
        cachingOptions.isNetworkAccessAllowed = false
        cachingOptions.resizeMode = .fast
        cachingOptions.version = .original
        cachingOptions.isSynchronous = false

        imageManager.startCachingImages(for: assets, targetSize: CGSize(width: 320, height: 320), contentMode: .default, options: cachingOptions)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}

extension PhotoSelectViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectPhoto(assets[indexPath.row])
        dismiss(animated: true, completion: nil)
    }
}

extension PhotoSelectViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell

//        if cell.requestID != -1
//        {
//            imageManager.cancelImageRequest(cell.requestID)
//            cell.requestID = -1
//        }

        let data = assets[indexPath.row]
        let options = PHImageRequestOptions()
        cell.requestID = imageManager.requestImage(for: data, targetSize: CGSize(width: 300, height: 300), contentMode: .default, options: options) { (image, _) in
            cell.imageView.image = image
            cell.requestID = -1
        }

        return cell
    }
}
