//
//  ViewController.swift
//  Tachograph
//
//  Created by larryhou on 30/6/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import UIKit

class RotableNavigationController: UINavigationController {
    override var shouldAutorotate: Bool {return true}
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {return .all}
}

class AlertManager {
    class func show(title: String? = nil, message: String? = nil, sender: UIViewController? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .cancel, handler: nil))
        if let keyWindow = UIApplication.shared.keyWindow {
            let controller: UIViewController?
            if sender != nil {
                controller = sender
            } else {
                controller = keyWindow.rootViewController
            }

            controller?.present(alert, animated: true, completion: nil)
        }
    }
}

class ViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        #if !NATIVE_DEBUG
        AssetManager.shared.removeUserStorage(development: true)
        #endif

        UIBarButtonItem.appearance().setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 20, weight: .light)], for: .normal)
        UINavigationBar.appearance().titleTextAttributes = [.font: UIFont.systemFont(ofSize: 30, weight: .thin)]
        UITabBarItem.appearance().setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 20, weight: .light)], for: .normal)
        UITabBarItem.appearance().titlePositionAdjustment.vertical = -10

        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor(white: 1.0, alpha: 0.75).setFill()
        UIRectFill(CGRect(origin: CGPoint(), size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        UINavigationBar.appearance().setBackgroundImage(image, for: .default)
        CameraModel.shared.networkObserver = networkObserver(_:)
    }

    lazy var errorColor: UIColor = { UIColor(red: 1.000, green: 0.894, blue: 0.894, alpha: 1.0) }()

    var connected: Bool = true
    func networkObserver(_ connected: Bool) {
        if self.connected != connected {
            self.tabBar.barTintColor = connected ? nil : self.errorColor
            self.connected = connected
        }
    }

    override var prefersStatusBarHidden: Bool { return true }

    override var shouldAutorotate: Bool { return frontestController?.shouldAutorotate ?? false }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { return frontestController?.preferredInterfaceOrientationForPresentation ?? .portrait}
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return frontestController?.supportedInterfaceOrientations ?? .portrait
    }

    var frontestController: UIViewController? {
        guard let selectedViewController = self.selectedViewController else { return nil }
        var current: UIViewController = selectedViewController
        while true {
            if current is UINavigationController, let navi = current as? UINavigationController {
                if let next = navi.viewControllers.last {
                    current = next
                } else {
                    break
                }
            } else
            if let next = current.presentedViewController {
                current = next
            } else {
                break
            }
        }
        return current
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
