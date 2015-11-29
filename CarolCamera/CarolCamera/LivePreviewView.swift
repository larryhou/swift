//
//  LivePreviewView.swift
//  CarolCamera
//
//  Created by larryhou on 29/11/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class LivePreivewView:UIView
{
    override class func layerClass() -> AnyClass
    {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var session:AVCaptureSession
    {
        get
        {
            return (self.layer as! AVCaptureVideoPreviewLayer).session
        }
        
        set
        {
            (self.layer as! AVCaptureVideoPreviewLayer).session = newValue
        }
    }
}

