//
//  PhotoViewController.swift
//  VisionPower
//
//  Created by larryhou on 06/09/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Photos
import Foundation
import UIKit

class PhotoViewController: UIViewController, PhotoSelectViewControllerDelegate
{
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectPhoto(_:)))
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap)
    }
    
    @objc func selectPhoto(_ sender:UITapGestureRecognizer)
    {
        let browseController = PhotoSelectViewController.instantiate(from: storyboard!, delegate: self)
        present(browseController, animated: true, completion: nil)
    }
    
    func didSelectPhoto(_ asset: PHAsset)
    {
        PHImageManager.default().requestImageData(for: asset, options: nil)
        { (data, uti, orientation, info) in
            if let image = data
            {
                self.replaceImage(with: UIImage(data: image))
            }
        }
    }
    
    func replaceImage(with image:UIImage?)
    {
        UIView.transition(with: imageView, duration: 1, options: [.transitionCrossDissolve, .preferredFramesPerSecond60], animations:
        { [unowned self] in
            self.imageView.image = image
        }, completion: nil)
    }
    
    @IBAction func visionModeUpdate(_ sender: UISwitch)
    {
        
    }
}
