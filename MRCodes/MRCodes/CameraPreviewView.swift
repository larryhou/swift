//
//  CameraPreviewView.swift
//  MRCodes
//
//  Created by larryhou on 13/12/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class CameraPreviewView:UIView
{
    override static func layerClass()->AnyClass
    {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var session:AVCaptureSession!
    {
        get
        {
            return (self.layer as! AVCaptureVideoPreviewLayer).session
        }
        
        set
        {
            (self.layer as! AVCaptureVideoPreviewLayer).session = newValue
        }
    }
}

class CameraOverlayView:UIView
{
    @IBOutlet weak var label:UILabel!
    @IBOutlet weak var type:UILabel!
    
    private var codes:[AVMetadataMachineReadableCodeObject]!
    private var faces:[AVMetadataFaceObject]!
    
    func setMetadataObjects(codes:[AVMetadataMachineReadableCodeObject], faces:[AVMetadataFaceObject])
    {
        self.codes = codes
        self.faces = faces
        setNeedsDisplay()
    }
    
    func getMRCEdges(from:AVMetadataMachineReadableCodeObject)->CGPath
    {
        var points:[CGPoint] = []
        for corner in (from.corners as! [NSDictionary])
        {
            let x = corner.valueForKeyPath("X") as! CGFloat
            let y = corner.valueForKeyPath("Y") as! CGFloat
            points.append(CGPoint(x: x, y: y))
        }
        
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, points[0].x, points[0].y)
        for i in 1..<points.count
        {
            CGPathAddLineToPoint(path, nil, points[i].x, points[i].y)
        }
        
        CGPathAddLineToPoint(path, nil, points[0].x, points[0].y)
        
        return path
    }
    
    func getFaceEdges(from:AVMetadataFaceObject)->CGPath
    {
        let path = CGPathCreateMutable()
        let radius:CGFloat = floor(min(5.0, from.bounds.width / 2, from.bounds.height))
        CGPathAddRoundedRect(path, nil, from.bounds, radius, radius)
        return path
    }
    
    override func drawRect(rect: CGRect)
    {
        let context = UIGraphicsGetCurrentContext()
        var target:CGPath!
        
        label.textColor = UIColor.whiteColor()
        label.text = ""
        
        type.text = ""
        if codes != nil && codes.count > 0
        {
            CGContextSaveGState(context)
            CGContextSetStrokeColorWithColor(context, UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0).CGColor)
            CGContextSetLineJoin(context, .Miter)
            CGContextSetLineCap(context, .Square)
            CGContextSetLineWidth(context, 2.0)
            
            for mrc in codes
            {
                let path = getMRCEdges(mrc)
                CGContextAddPath(context, path)
                if target == nil
                {
                    target = path
                    type.text = mrc.type
                    
                    label.text = mrc.stringValue
                    label.sizeToFit()
                    
                    if mrc.stringValue != nil
                    {
                        UIPasteboard.generalPasteboard().string = mrc.stringValue
                    }
                }
            }
            
            CGContextStrokePath(context)
            CGContextRestoreGState(context)
        }
        
        if target != nil
        {
            CGContextSaveGState(context)
            CGContextAddPath(context, target)
            CGContextSetFillColorWithColor(context, UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.2).CGColor)
            CGContextFillPath(context)
            CGContextRestoreGState(context)
        }
        
        if faces != nil && faces.count > 0
        {
            CGContextSaveGState(context)
            CGContextSetStrokeColorWithColor(context, UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0).CGColor)
            CGContextSetLineJoin(context, .Miter)
            CGContextSetLineCap(context, .Square)
            CGContextSetLineWidth(context, 1.0)
            
            for mrc in faces
            {
                CGContextAddPath(context, getFaceEdges(mrc))
            }
            
            CGContextStrokePath(context)
            CGContextRestoreGState(context)
        }
        
    }
}