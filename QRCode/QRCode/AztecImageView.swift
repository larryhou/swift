//
//  AztecImageView.swift
//  QRCode
//
//  Created by larryhou on 23/12/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class AztecImageView:UIImageView
{
    private var ib_inputMessage = "larryhou"
    private var ib_inputCompactStyle = false
    
    @IBInspectable
    var inputMessage:String
    {
        get {return ib_inputMessage}
        set
        {
            ib_inputMessage = newValue
            drawAztecImage()
        }
    }
    
    @IBInspectable
    var inputCompactStyle:Bool
    {
        get {return ib_inputCompactStyle}
        set
        {
            ib_inputCompactStyle = newValue
            drawAztecImage()
        }
    }
    
    func drawAztecImage()
    {
        let filter = CIFilter(name: "CIAztecCodeGenerator")
        let data = NSString(string: inputMessage).dataUsingEncoding(NSUTF8StringEncoding)
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue(inputCompactStyle, forKey: "inputCompactStyle")
        
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
        drawAztecImage()
    }
}
