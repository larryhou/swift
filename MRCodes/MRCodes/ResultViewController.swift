//
//  ResultViewController.swift
//  MRCodes
//
//  Created by larryhou on 2018/3/25.
//  Copyright © 2018 larryhou. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class ResultViewController: UIViewController
{
    var mrcObjects:[AVMetadataMachineReadableCodeObject]!
    
    @IBOutlet weak var resultView: UIView!
    @IBOutlet weak var mrcContent: UITextView!
    @IBOutlet weak var mrcTitle: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        let frame = view.frame
        view.frame = frame.offsetBy(dx: 0, dy: frame.height - resultView.frame.height)
        
        reload()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    func reload()
    {
        if let data = mrcObjects.first, let stringValue = data.stringValue
        {
            if mrcTitle.text != data.type.rawValue
            {
                mrcTitle.text = data.type.rawValue
            }
            
            if mrcContent.text != stringValue
            {
                mrcContent.text = stringValue
            }
        }
    }
}
