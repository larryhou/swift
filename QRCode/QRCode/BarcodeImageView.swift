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
class BarcodeImageView:GeneratorImageView
{
    @IBInspectable
    var inputQuietSpace:Double = 0.0 // 7.0[0.0,20.0]
    {
        didSet { drawBarcodeImage() }
    }
    
    @IBInspectable
    var inputMessage:String = "larryhou"
    {
        didSet { drawBarcodeImage() }
    }
    
    func drawBarcodeImage()
    {
        let filter = CIFilter(name: "CICode128BarcodeGenerator")
        let data = inputMessage.data(using: .utf8)
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue(inputQuietSpace, forKey: "inputQuietSpace")
        
        self.image = stripOutputImage(of: filter)
    }
    
    override func prepareForInterfaceBuilder()
    {
        drawBarcodeImage()
    }
}
