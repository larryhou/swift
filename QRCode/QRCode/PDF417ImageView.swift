//
//  PDF417ImageView.swift
//  QRCode
//
//  Created by larryhou on 24/12/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import UIKit

class GeneratorImageView: UIImageView
{
    func stripOutputImage(of filter:CIFilter?)->UIImage?
    {
        guard let image = filter?.outputImage else {return nil}
        UIGraphicsBeginImageContext(frame.size)
        defer
        {
            UIGraphicsEndImageContext()
        }
        
        guard let context = UIGraphicsGetCurrentContext() else {return nil}
        
        context.interpolationQuality = .none
        
        if let cgImage = CIContext().createCGImage(image, from: image.extent)
        {
            context.draw(cgImage, in: context.boundingBoxOfClipPath)
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

@IBDesignable
class PDF417ImageView:GeneratorImageView
{
    @IBInspectable
    var inputMessage:String = "larryhou"
    {
        didSet { drawPDF417Image() }
    }
    
    @IBInspectable
    var inputMinWidth:Float = 56.0 // 0.0[56.0,583.0]
    {
        didSet { drawPDF417Image() }
    }
    
    @IBInspectable
    var inputMaxWidth:Float = 56.0 // 0.0[56.0,583.0]
    {
        didSet { drawPDF417Image() }
    }
    
    @IBInspectable
    var inputMinHeight:Float = 13.0 // 0.0[13.0,283.0]
    {
        didSet { drawPDF417Image() }
    }
    
    @IBInspectable
    var inputMaxHeight:Float = 13.0 // 0.0[13.0,283.0]
    {
        didSet { drawPDF417Image() }
    }
    
    @IBInspectable
    var inputDataColumns:Float = 10.0 // 0.0[1.0,30.0]
    {
        didSet { drawPDF417Image() }
    }
    
    @IBInspectable
    var inputRows:Float = 10.0 // 0.0[3.0,90.0]
    {
        didSet { drawPDF417Image() }
    }
    
    @IBInspectable
    var inputPreferredAspectRatio:Float = 3.0 // 0.0[0.0,9223372036854775808.0]
    {
        didSet { drawPDF417Image() }
    }
    
    @IBInspectable
    var inputCompactionMode:Float = 2.0 // 0.0[0.0,3.0]
    {
        didSet { drawPDF417Image() }
    }
    
    @IBInspectable
    var inputCorrectionLevel:Int = 4 // 0[0,8]
    {
        didSet { drawPDF417Image() }
    }
    
    @IBInspectable
    var inputCompactStyle:Bool = false
    {
        didSet { drawPDF417Image() }
    }
    
    @IBInspectable
    var inputAlwaysSpecifyCompaction:Bool = false
    {
        didSet { drawPDF417Image() }
    }
    
    func drawPDF417Image()
    {
        let filter = CIFilter(name: "CIPDF417BarcodeGenerator")
        
        let data = inputMessage.data(using: .utf8)
        
        filter?.setValue(data, forKey: "inputMessage")
//        filter?.setValue(inputMinWidth, forKey: "inputMinWidth")
//        filter?.setValue(inputMaxWidth, forKey: "inputMaxWidth")
//        filter?.setValue(inputMinHeight, forKey: "inputMinHeight")
//        filter?.setValue(inputMaxHeight, forKey: "inputMaxHeight")
//        filter?.setValue(inputDataColumns, forKey: "inputDataColumns")
//        filter?.setValue(inputRows, forKey: "inputRows")
        filter?.setValue(inputPreferredAspectRatio, forKey: "inputPreferredAspectRatio")
        filter?.setValue(inputCompactionMode, forKey: "inputCompactionMode")
        filter?.setValue(inputCompactStyle, forKey: "inputCompactStyle")
        filter?.setValue(inputCorrectionLevel, forKey: "inputCorrectionLevel")
        filter?.setValue(inputAlwaysSpecifyCompaction, forKey: "inputAlwaysSpecifyCompaction")
        
        self.image = stripOutputImage(of: filter)
    }
    
    override func prepareForInterfaceBuilder()
    {
        drawPDF417Image()
    }
}
