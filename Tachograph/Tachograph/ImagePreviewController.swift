//
//  ImagePreviewController.swift
//  Tachograph
//
//  Created by larryhou on 01/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit

extension CGAffineTransform
{
    var scaleX:CGFloat
    {
        return sqrt(a*a + c*c)
    }
    
    var scaleY:CGFloat
    {
        return sqrt(b*b + d*d)
    }
    
    var scale:(CGFloat, CGFloat)
    {
        return (self.scaleX, self.scaleY)
    }
}

class ImagePreviewController:ImagePeekController, ReusableObject
{
    static func instantiate(_ data: Any?) -> ReusableObject
    {
        let storyboard = data as! UIStoryboard
        return storyboard.instantiateViewController(withIdentifier: "ImagePreviewController") as! ImagePreviewController
    }
    
    @IBOutlet weak var timelabel: UILabel!
    
    var scaleRange:(CGFloat, CGFloat) = (1.0, 3.0)
    override var shouldAutorotate: Bool {return true}
    var frameImage = CGRect()
    var dateFormatter = DateFormatter()
    
    var panGestureRecognizer:UIPanGestureRecognizer?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        scaleRange = (scaleRange.0, view.frame.height / image.frame.height)
        frameImage = image.frame
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss E"
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchUpdate(sender:)))
        view.addGestureRecognizer(pinch)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(pinchUpdate(sender:)))
        image.addGestureRecognizer(pan)
        panGestureRecognizer = pan
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationUpdate), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    var lastUrl:String?
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if lastUrl == self.url {return}
        
        if let data = self.data
        {
            timelabel.text = dateFormatter.string(from: data.timestamp)
        }
        
        orientationUpdate()
    }
    
    var baseTransform = CGAffineTransform.identity
    
    @objc func orientationUpdate()
    {
        guard let navigationController = self.navigationController else {return}
        let rotation, alpha:CGFloat
        let orientation = UIDevice.current.orientation
        let textColor:UIColor
        if orientation.isLandscape
        {
            alpha = 0
            let scale = max(view.frame.height / frameImage.width, view.frame.width / frameImage.height)
            scaleRange = (scale, scale)
            rotation = orientation == .landscapeLeft ?  CGFloat.pi / 2 : -CGFloat.pi / 2
            textColor = .white
            panGestureRecognizer?.isEnabled = false
        }
        else
        {
            alpha = 1
            scaleRange = (view.frame.width / frameImage.width, view.frame.height / frameImage.height)
            rotation = 0//orientation == .portrait ?  0 : CGFloat.pi
            panGestureRecognizer?.isEnabled = true
            textColor = .black
        }
        
        let transform = CGAffineTransform(rotationAngle: rotation)
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.9)
        {
            navigationController.navigationBar.alpha = alpha
            self.image.transform = transform.scaledBy(x: self.scaleRange.0, y: self.scaleRange.0)
            self.timelabel.textColor = textColor
        }
        
        baseTransform = transform
        animator.addCompletion
        { _ in
            self.positionAdjust()
        }
        animator.startAnimation()
    }
    
    var panAnimator:UIViewPropertyAnimator?
    
    var origin:CGPoint = CGPoint()
    @objc func panUpdate(sender:UIPanGestureRecognizer)
    {
        switch sender.state
        {
            case .began:
                origin = image.frame.origin
            case .changed:
                let offset = sender.translation(in: image.superview)
                image.frame.origin.x = origin.x + offset.x
                image.frame.origin.y = origin.y + offset.y
            case .ended:
                positionAdjust()
            default:break
        }
    }
    
    func positionAdjust()
    {
        var rect = image.superview!.convert(image.frame, to: view)
        rect.origin.x = max(min(rect.origin.x, 0), view.frame.width - rect.width)
        rect.origin.y = max(min(rect.origin.y, 0), (view.frame.height - rect.height)/2)
        rect = view.convert(rect, to: image.superview)
        let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut)
        {
            self.image.frame = rect
        }
        animator.startAnimation()
    }
    
    func scaleAdjust(relatedUpdate:Bool = true, fitted:Bool = false)
    {
        scale = fitted ? scaleRange.0 : min(max(scaleRange.0, scale), scaleRange.1)
        
        let transform = baseTransform.scaledBy(x: scale, y: scale)
        let animator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.85)
        {
            self.image.transform = transform
        }
        if (relatedUpdate) {animator.addCompletion{ _ in self.positionAdjust() }}
        animator.startAnimation()
    }
    
    var scale:CGFloat = 1.0
    @objc func pinchUpdate(sender:UIPinchGestureRecognizer)
    {
        switch sender.state
        {
            case .began:
                sender.scale = image.transform.scaleX
            case .changed:
                scale = sender.scale
                image.transform = baseTransform.scaledBy(x: scale, y: scale)
            case .ended:
                scaleAdjust()
            default:break
        }
    }
}

class ImagePeekController: UIViewController
{
    var url:String!
    var data:CameraModel.CameraAsset?
    var index:Int = -1
    
    @IBOutlet weak var image:UIImageView!
    @IBOutlet weak var indicator:UIActivityIndicatorView!
    
    override var previewActionItems: [UIPreviewActionItem]
    {
        var actions:[UIPreviewAction] = []
        actions.append(UIPreviewAction(title: "保存到相册", style: .default)
        { (action:UIPreviewAction, ctrl:UIViewController) in
            
        })
        actions.append(UIPreviewAction(title: "识别二维码", style: .default)
        { (action:UIPreviewAction, ctrl:UIViewController) in
            
        })
        actions.append(UIPreviewAction(title: "分享", style: .default)
        { (action:UIPreviewAction, ctrl:UIViewController) in
            
        })
        return actions
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        indicator.stopAnimating()
        
        self.image.image = nil
        
        let manager = AssetManager.shared
        if let location = manager.get(cache: url)
        {
            image.image = try! UIImage(data: Data(contentsOf: location))
        }
        else
        {
            indicator.startAnimating()
            manager.load(url: url, completion:
            {
                self.indicator?.stopAnimating()
                self.image?.image = UIImage(data: $1)
            })
        }
    }
}
