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
    
    @IBInspectable
    var inputMessage:String
    {
        get
        {
            return self.ib_inputMessage
        }
        
        set
        {
            self.ib_inputMessage = newValue
            renderQRImage()
        }
    }
    
    private func renderQRImage()
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
    
    override func prepareForInterfaceBuilder()
    {
        renderQRImage()
    }
}