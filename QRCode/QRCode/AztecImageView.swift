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
class AztecImageView: GeneratorImageView {
    @IBInspectable
    var inputMessage: String = "larryhou" {
        didSet { drawAztecImage() }
    }

    @IBInspectable
    var inputCompactStyle: Bool = false {
        didSet { drawAztecImage() }
    }

    @IBInspectable
    var inputCorrectionLevel: Float = 50.0 // 23.0[5.0,95.0]
    {
        didSet { drawAztecImage() }
    }

    @IBInspectable
    var inputLayers: Float = 1.0 // 0.0[1.0,32.0]
    {
        didSet { drawAztecImage() }
    }

    func drawAztecImage() {
        let filter = CIFilter(name: "CIAztecCodeGenerator")
        let data = inputMessage.data(using: .utf8)

        filter?.setValue(data, forKey: "inputMessage")
//        filter?.setValue(inputLayers, forKey: "inputLayers")
//        filter?.setValue(inputCompactStyle, forKey: "inputCompactStyle")
        filter?.setValue(inputCorrectionLevel, forKey: "inputCorrectionLevel")

        self.image = stripOutputImage(of: filter)
    }

    override func prepareForInterfaceBuilder() {
        drawAztecImage()
    }
}
