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
class AztecImageView:GeneratorImageView
{
    private static let DEFAULT_MESSAGE = "larryhou"
    
    private var ib_inputMessage = AztecImageView.DEFAULT_MESSAGE
    private var ib_inputCompactStyle = false
    
    @IBInspectable
    var inputMessage:String
    {
        get {return ib_inputMessage}
        set
        {
            ib_inputMessage = newValue == "" ? AztecImageView.DEFAULT_MESSAGE : newValue
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
        let data = inputMessage.data(using: .utf8)
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue(inputCompactStyle, forKey: "inputCompactStyle")
        
        self.image = stripOutputImage(of: filter)
    }
    
    override func prepareForInterfaceBuilder()
    {
        drawAztecImage()
    }
}
