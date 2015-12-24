//
//  PDF417ImageView.swift
//  QRCode
//
//  Created by larryhou on 24/12/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class PDF417ImageView:UIImageView
{
    private static let DEFAULT_MESSAGE = "larryhou"
    
    private var ib_inputMessage = PDF417ImageView.DEFAULT_MESSAGE
    private var ib_preferredAspectRatio = 3.0
    private var ib_compactionMode = 2.0
    private var ib_compactStyle = false
    private var ib_alwaysSpecifyCompaction = false
    
    @IBInspectable
    var inputMessage:String
    {
        get {return ib_inputMessage}
        set
        {
            ib_inputMessage = newValue == "" ? PDF417ImageView.DEFAULT_MESSAGE : newValue
            drawPDF417Image()
        }
    }
    
    @IBInspectable
    var preferredAspectRatio:Double
    {
        get {return ib_preferredAspectRatio}
        set
        {
            ib_preferredAspectRatio = newValue
            drawPDF417Image()
        }
    }
    
    @IBInspectable
    var compactionMode:Double
    {
        get {return ib_compactionMode}
        set
        {
            ib_compactionMode = newValue
            drawPDF417Image()
        }
    }
    
    @IBInspectable
    var compactStyle:Bool
    {
        get {return ib_compactStyle}
        set
        {
            ib_compactStyle = newValue
            drawPDF417Image()
        }
    }
    
    @IBInspectable
    var alwaysSpecifyCompaction:Bool
    {
        get {return ib_alwaysSpecifyCompaction}
        set
        {
            ib_alwaysSpecifyCompaction = newValue
            drawPDF417Image()
        }
    }
    
    func drawPDF417Image()
    {
        let filter = CIFilter(name: "CIPDF417BarcodeGenerator")
        let data = NSString(string: inputMessage).dataUsingEncoding(NSUTF8StringEncoding)
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue(preferredAspectRatio, forKey: "inputPreferredAspectRatio")
        filter?.setValue(compactionMode, forKey: "inputCompactionMode")
        filter?.setValue(compactStyle, forKey: "inputCompactStyle")
        filter?.setValue(alwaysSpecifyCompaction, forKey: "inputAlwaysSpecifyCompaction")
        
        let image = (filter?.outputImage)!
        let scale = frame.width / image.extent.width
        UIGraphicsBeginImageContext(CGSize(width: image.extent.width * scale, height: image.extent.height * scale))
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetInterpolationQuality(context, .None)
        
        let cgImage = CIContext().createCGImage(image, fromRect: image.extent)
        CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.image = scaledImage
    }
    
    override func prepareForInterfaceBuilder()
    {
        drawPDF417Image()
    }
}