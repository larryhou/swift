//
//  ImageReviewController.swift
//  Tachograph
//
//  Created by larryhou on 03/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit

class ImageScrollController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
    var index:Int = -1
    var imageAssets:[CameraModel.CameraAsset]?
    var manager:InstanceManager<ImagePreviewController>!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        manager = InstanceManager<ImagePreviewController>()
        self.dataSource = self
        self.delegate = self
        
        let review = manager.fetch(storyboard)
        review.index = index
        if let imageAssets = self.imageAssets
        {
            review.url = imageAssets[index].url
            review.data = imageAssets[index]
        }
        AssetManager.shared.removeUserStorage(development: true)
        setViewControllers([review], direction: .forward, animated: false, completion: nil)
    }
    
    func fetchImageController(index:Int)->ImagePreviewController?
    {
        if let imageAssets = self.imageAssets
        {
            if index >= 0 && index < imageAssets.count
            {
                let data = imageAssets[index]
                let review = manager.fetch(storyboard)
                print("index", index, data)
                review.index = index
                review.url = data.url
                review.data = data
                return review
            }
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        for review in previousViewControllers
        {
            manager.recycle(target: review as! ImagePreviewController)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        if let controller = viewController as? ImagePreviewController
        {
            let review = fetchImageController(index: controller.index - 1)
            review?.view.backgroundColor = controller.view.backgroundColor
            return review
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        if let controller = viewController as? ImagePreviewController
        {
            let review = fetchImageController(index: controller.index + 1)
            review?.view.backgroundColor = controller.view.backgroundColor
            return review
        }
        return nil
    }
}
