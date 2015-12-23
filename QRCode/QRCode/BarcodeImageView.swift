//
//  BarcodeImageView.swift
//  QRCode
//
//  Created by larryhou on 22/12/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class BarcodeImageView:UIImageView
{
    private static let DEFAULT_MESSAGE = "larryhou"
    
    private var ib_inputQuietSpace:Double = 7.0
    private var ib_inputMessage:String = BarcodeImageView.DEFAULT_MESSAGE
    
    @IBInspectable
    var inputQuietSpace:Double
    {
        get {return ib_inputQuietSpace}
        set
        {
            ib_inputQuietSpace = newValue
            drawBarcodeImage()
        }
    }
    
    @IBInspectable
    var inputMessage:String
    {
        get {return ib_inputMessage}
        set
        {
            ib_inputMessage = newValue == "" ? BarcodeImageView.DEFAULT_MESSAGE : newValue
            drawBarcodeImage()
        }
    }
    
    func drawBarcodeImage()
    {
        let filter = CIFilter(name: "CICode128BarcodeGenerator")
        let data = NSString(string: inputMessage).dataUsingEncoding(NSUTF8StringEncoding)
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue(inputQuietSpace, forKey: "inputQuietSpace")
        
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
        drawBarcodeImage()
    }
}
