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
class QRImageView:GeneratorImageView
{
    private static let DEFAULT_MESSAGE = "larryhou"
    
    private var ib_inputMessage:String = QRImageView.DEFAULT_MESSAGE
    private var ib_useCoreGraphics = true
    private var ib_correctionLevel = "M"
    
    @IBInspectable
    var correctionLevel:String
    {
        get {return ib_correctionLevel}
        set
        {
            self.ib_correctionLevel = newValue
            self.drawQRImage()
        }
    }
    
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
            self.ib_inputMessage = newValue == "" ? QRImageView.DEFAULT_MESSAGE : newValue
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
        let data = inputMessage.data(using: .utf8)
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        
        var image = (filter?.outputImage)!
        let scale = self.frame.width / image.extent.width
        image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        self.image = UIImage(ciImage: image)
    }
    
    private func drawQRImageWithCoreGraphics()
    {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        let data = inputMessage.data(using: .utf8)
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        
        
        
        self.image = stripOutputImage(of: filter)
    }
    
    override func prepareForInterfaceBuilder()
    {
        drawQRImage()
    }
}
