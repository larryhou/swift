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
class QRImageView: GeneratorImageView {
    @IBInspectable
    var inputCorrectionLevel: String = "M" //M[L:7%,M:15%,Q:25%,H:30%]
    {
        didSet {
            self.drawQRImage()
        }
    }

    @IBInspectable
    var useCoreGraphics: Bool = true {
        didSet {
            self.drawQRImage()
        }
    }

    @IBInspectable
    var inputMessage: String = "larryhou" {
        didSet {
            self.drawQRImage()
        }
    }

    func drawQRImage() {
        if useCoreGraphics {
            drawQRImageWithCoreGraphics()
        } else {
            drawQRImageWithScaleTransform()
        }
    }

    private func drawQRImageWithScaleTransform() {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        let data = inputMessage.data(using: .utf8)

        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue(inputCorrectionLevel, forKey: "inputCorrectionLevel")

        var image = (filter?.outputImage)!
        let scale = self.frame.width / image.extent.width
        image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        self.image = UIImage(ciImage: image)
    }

    private func drawQRImageWithCoreGraphics() {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        let data = inputMessage.data(using: .utf8)

        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue(inputCorrectionLevel, forKey: "inputCorrectionLevel")

        self.image = stripOutputImage(of: filter)
    }

    override func prepareForInterfaceBuilder() {
        drawQRImage()
    }
}
