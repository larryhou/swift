//
//  QRImageView.swift
//  QRCode
//
//  Created by larryhou on 21/12/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class QRImageView:UIImageView
{
    var ib_inputMessage:String = "larryhou"
    var ib_useCoreGraphics = true
    
    @IBInspectable
    var useCoreGraphics:Bool
    {
        get {return ib_useCoreGraphics}
        set
        {
            self.ib_useCoreGraphics = newValue
            self.drawQRImage()
        }
    }
    
    @IBInspectable
    var inputMessage:String
    {
        get {return self.ib_inputMessage}
        
        set
        {
            self.ib_inputMessage = newValue
            self.drawQRImage()
        }
    }
    
    func drawQRImage()
    {
        if useCoreGraphics
        {
            drawQRImageWithCoreGraphics()
        }
        else
        {
            drawQRImageWithScaleTransform()
        }
    }
    
    private func drawQRImageWithScaleTransform()
    {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        let data = NSString(string: inputMessage).dataUsingEncoding(NSUTF8StringEncoding)
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        
        var image = (filter?.outputImage)!
        let scale = self.frame.width / image.extent.size.width
        image = image.imageByApplyingTransform(CGAffineTransformMakeScale(scale, scale))
        
        self.image = UIImage(CIImage: image)
    }
    
    private func drawQRImageWithCoreGraphics()
    {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        let data = NSString(string: inputMessage).dataUsingEncoding(NSUTF8StringEncoding)
        
        filter?.setValue(data, forKey: "inputMessage")
        
        let image = (filter?.outputImage)!
        UIGraphicsBeginImageContext(frame.size)
        
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
        drawQRImage()
    }
}