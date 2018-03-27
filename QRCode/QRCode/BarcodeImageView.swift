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
