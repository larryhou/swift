//
//  StandardPageController.swift
//  Tachograph
//
//  Created by larryhou on 09/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit

protocol PageProtocol {
    static func instantiate(_ storyboard: UIStoryboard) -> PageProtocol
    var pageAsset: Any? { get set }
    var index: Int { get set }
}

class PageController<PageType, PageAssetType>: UIPageViewController, UIPageViewControllerDataSource where PageType: PageProtocol & UIViewController, PageAssetType: Any {
    var index: Int = -1
    var pageControllers: [PageType] = []
    var pageAssets: [PageAssetType]?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self

        pageControllers.append(instantiate())
        pageControllers.append(instantiate())
        pageControllers.append(instantiate())
        if let initController = fetchController(forward: true, position: nil) {
            setViewControllers([initController], direction: .forward, animated: false, completion: nil)
        }
    }

    private func instantiate() -> PageType {
        return PageType.instantiate(storyboard!) as! PageType
    }

    func fetchController(forward: Bool, position: PageType?) -> PageType? {
        guard let assets = self.pageAssets else {return nil}

        let dataIndex: Int
        var playController: PageType
        if let position = position {
            var viewIndex = pageControllers.index(of: position)!
            if forward {
                viewIndex = viewIndex == pageControllers.count - 1 ? 0 : viewIndex + 1
                dataIndex = position.index + 1
            } else {
                viewIndex = viewIndex == 0 ? pageControllers.count - 1 : viewIndex - 1
                dataIndex = position.index - 1
            }

            if dataIndex < 0 || dataIndex >= assets.count {return nil}
            playController = pageControllers[viewIndex]
        } else {
            playController = pageControllers[0]
            dataIndex = self.index
        }

        playController.pageAsset = assets[dataIndex]
        playController.index = dataIndex
        return playController
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let controller = viewController as? PageType {
            return fetchController(forward: false, position: controller)
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let controller = viewController as? PageType {
            return fetchController(forward: true, position: controller)
        }
        return nil
    }
}
