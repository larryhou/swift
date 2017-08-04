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
    
    var scaleRange:(CGFloat, CGFloat) = (1.0, 3.0)
    override var shouldAutorotate: Bool {return true}
    var frameImage = CGRect()
    
    weak var panGesture:UIPanGestureRecognizer?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        presentController = self
        scaleRange = (scaleRange.0, view.frame.height / image.frame.height)
        frameImage = image.frame
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchUpdate(sender:)))
        view.addGestureRecognizer(pinch)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panUpdate(sender:)))
        image.addGestureRecognizer(pan)
        panGesture = pan
        
        let press = UILongPressGestureRecognizer(target: self, action: #selector(pressUpdate(sender:)))
        image.addGestureRecognizer(press)
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationUpdate), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    var lastUrl:String?
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if lastUrl == url {return}
        lastUrl = url
        
        orientationUpdate()
    }
    
    @objc func pressUpdate(sender:UILongPressGestureRecognizer)
    {
        if sender.state != .began {return}
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "保存到相册", style: .default, handler:{ _ in self.saveToAlbum() }))
        alertController.addAction(UIAlertAction(title: "分享", style: .default, handler:{ _ in self.share() }))
        alertController.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    var baseTransform = CGAffineTransform.identity
    
    @objc func orientationUpdate()
    {
        guard let navigationController = self.navigationController else {return}
        let rotation, alpha:CGFloat
        let orientation = UIDevice.current.orientation
        if orientation.isLandscape
        {
            alpha = 0
            let scale = max(view.frame.height / frameImage.width, view.frame.width / frameImage.height)
            scaleRange = (scale, scale)
            rotation = orientation == .landscapeLeft ?  CGFloat.pi / 2 : -CGFloat.pi / 2
            panGesture?.isEnabled = false
        }
        else
        {
            alpha = 1
            scaleRange = (view.frame.width / frameImage.width, view.frame.height / frameImage.height)
            rotation = 0//orientation == .portrait ?  0 : CGFloat.pi
            panGesture?.isEnabled = true
        }
        
        let transform = CGAffineTransform(rotationAngle: rotation)
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.9)
        { [unowned self] in
            navigationController.navigationBar.alpha = alpha
            self.image.transform = transform.scaledBy(x: self.scaleRange.0, y: self.scaleRange.0)
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
        { [unowned self] in
            self.image.frame = rect
        }
        animator.startAnimation()
    }
    
    func scaleAdjust(relatedUpdate:Bool = true, fitted:Bool = false)
    {
        scale = fitted ? scaleRange.0 : min(max(scaleRange.0, scale), scaleRange.1)
        
        let transform = baseTransform.scaledBy(x: scale, y: scale)
        let animator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.85)
        { [unowned self] in
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
    
    weak var presentController:UIViewController?
    
    override var previewActionItems: [UIPreviewActionItem]
    {
        var actions:[UIPreviewAction] = []
        actions.append(UIPreviewAction(title: "保存到相册", style: .default)
        { (action:UIPreviewAction, ctrl:UIViewController) in
            self.saveToAlbum()
        })
        actions.append(UIPreviewAction(title: "分享", style: .default)
        { (action:UIPreviewAction, ctrl:UIViewController) in
            self.share()
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
    
    func share()
    {
        guard let url = self.url, let presentController = self.presentController else {return}
        if let location = AssetManager.shared.get(cache: url)
        {
            let controller = UIActivityViewController(activityItems: [location], applicationActivities: nil)
            presentController.present(controller, animated: true, completion: nil)
        }
    }
    
    func saveToAlbum()
    {
        guard let url = self.url else {return}
        if let location = AssetManager.shared.get(cache: url)
        {
            if let data = try? Data(contentsOf: location), let image = UIImage(data: data)
            {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    
    @objc func image(_ image:UIImage, didFinishSavingWithError error:NSError?, contextInfo context:Any?)
    {
        guard let presentController = self.presentController else {return}
        
        var message:String?
        
        let title:String
        if error == nil
        {
            title = "图片保存成功"
        }
        else
        {
            title = "图片保存失败"
            message = error.debugDescription
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "知道了", style: .cancel, handler: nil))
        presentController.present(alert, animated: true, completion: nil)
    }
}
