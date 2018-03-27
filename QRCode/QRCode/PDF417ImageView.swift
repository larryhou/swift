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
        
        let data = inputMessage.data(using: .utf8)
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue(preferredAspectRatio, forKey: "inputPreferredAspectRatio")
        filter?.setValue(compactionMode, forKey: "inputCompactionMode")
        filter?.setValue(compactStyle, forKey: "inputCompactStyle")
        filter?.setValue(alwaysSpecifyCompaction, forKey: "inputAlwaysSpecifyCompaction")
        
        self.image = stripOutputImage(of: filter)
    }
    
    override func prepareForInterfaceBuilder()
    {
        drawPDF417Image()
    }
}
