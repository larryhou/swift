//
//  PhotoPreviewController.swift
//  PhotoPreview
//
//  Created by larryhou on 3/19/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import Foundation
import UIKit

class PhotoPreviewController: UIViewController, UIScrollViewDelegate {
	private var background: UIImageView!
	private var zoomView: UIImageView!
	private var preview: UIScrollView!

	var dirty: Bool = true
	var dataIndex: Int = -1
	var image: UIImage!

	override func viewDidLoad() {
		super.viewDidLoad()

		view.clipsToBounds = true

		preview = UIScrollView()
		preview.frame = UIScreen.mainScreen().applicationFrame
		preview.contentSize = preview.frame.size
		preview.minimumZoomScale = 0.01
		preview.maximumZoomScale = 2.00
		preview.delegate = self
		view.addSubview(preview)

		preview.pinchGestureRecognizer.addTarget(self, action: "pinchUpdated:")
		setPreviewAutoLayout()

		var tap = UITapGestureRecognizer()
		tap.numberOfTapsRequired = 2
		tap.addTarget(self, action: "doubleTapZoom:")
		preview.addGestureRecognizer(tap)
	}

	func setPreviewAutoLayout() {
		var views: [NSObject: AnyObject] = [:]
		views.updateValue(preview, forKey: "preview")

		preview.setTranslatesAutoresizingMaskIntoConstraints(false)
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[preview]|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views))
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[preview]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: views))
	}

	override func viewWillAppear(animated: Bool) {
		if !dirty {
			return
		}

		dirty = false
		if zoomView != nil && zoomView.superview != nil {
			zoomView.removeFromSuperview()
		}

		zoomView = UIImageView(image: image)
		preview.addSubview(zoomView)

		updateBackgroundImage()

		preview.zoomScale = 0.01

		repairImageZoom(useAnimation: true)
		alignImageAtCenter()
	}

	func updateBackgroundImage() {
		if background != nil && background.superview != nil {
			background.removeFromSuperview()
		}

		background = UIImageView(image: createBackgroundImage(inputImage: image))
		view.insertSubview(background, atIndex: 0)

		var frame = background.frame
		frame.origin.x = (view.frame.width - frame.width) / 2.0
		frame.origin.y = (view.frame.height - frame.height) / 2.0
		background.frame = frame
	}

	func createBackgroundImage(inputImage input: UIImage) -> UIImage? {
		let bounds = UIScreen.mainScreen().bounds
		let size = CGSize(width: bounds.width / 2.0, height: bounds.height / 2.0)

		let scale = max(size.width / input.size.width, size.height / input.size.height)

		UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
		let context = UIGraphicsGetCurrentContext()

		CGContextScaleCTM(context, scale, scale)

		let tx = (size.width / scale - input.size.width) / 2.0
		let ty = (size.height / scale - input.size.height) / 2.0
		CGContextTranslateCTM(context, tx, ty)

		input.drawAtPoint(CGPoint(x: 0, y: 0))

		var data: UIImage = UIGraphicsGetImageFromCurrentImageContext()!

		UIGraphicsEndImageContext()

		var filter = CIFilter(name: "CIGaussianBlur")
		filter.setValue(CIImage(image: data), forKey: kCIInputImageKey)
		filter.setValue(20.0, forKey: kCIInputRadiusKey)
		return UIImage(CIImage: filter.outputImage)
	}

	func doubleTapZoom(gesture: UITapGestureRecognizer) {
		let MAX_SIZE_W = zoomView.frame.width / preview.zoomScale

		var scale: CGFloat
		if zoomView.frame.width > preview.frame.width + 0.0001 {
			scale = preview.frame.width / MAX_SIZE_W
		} else {
			scale = 1.0 / UIScreen.mainScreen().scale
		}

		preview.setZoomScale(scale, animated: true)
	}

	func pinchUpdated(gesture: UIPinchGestureRecognizer) {
		switch gesture.state {
			case .Began:
				preview.panGestureRecognizer.enabled = false

			case .Ended:
				preview.panGestureRecognizer.enabled = true
				repairImageZoom()

			default:break
		}
	}

	func setImage(image: UIImage, dataIndex index: Int) {
		self.dirty = true

		self.dataIndex = index
		self.image = image
	}

	func restoreImageZoom() {
		let MAX_SIZE_W = zoomView.frame.width / preview.zoomScale

		preview.zoomScale = preview.frame.width / MAX_SIZE_W
	}

	func repairImageZoom(useAnimation flag: Bool = true) {
		let MAX_SIZE_W = zoomView.frame.width / preview.zoomScale

		var scale: CGFloat!
		if zoomView.frame.width < view.frame.width {
			scale = view.frame.width / MAX_SIZE_W
		} else
		if zoomView.frame.width > (MAX_SIZE_W / UIScreen.mainScreen().scale) {
			scale = 1.0 / UIScreen.mainScreen().scale
		}

		if scale != nil {
			if flag {
				preview.setZoomScale(scale, animated: true)
			} else {
				preview.zoomScale = scale
			}
		}
	}

	func alignImageAtCenter() {
		var inset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		if zoomView.frame.width < view.frame.width {
			inset.left = (view.frame.width - zoomView.frame.width) / 2.0
		} else {
			inset.left = 0.0
		}

		if zoomView.frame.height < view.frame.height {
			inset.top = (view.frame.height - zoomView.frame.height) / 2.0
		} else {
			inset.top = 0.0
		}

		preview.contentInset = inset
	}

	func scrollViewDidZoom(scrollView: UIScrollView) {
		alignImageAtCenter()
	}

	override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
		updateBackgroundImage()

		repairImageZoom()
		alignImageAtCenter()
	}

	func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
		return zoomView
	}

	deinit {
		preview.pinchGestureRecognizer.removeObserver(self, forKeyPath: "pinchUpdated:")
	}
}
