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
        view.isHidden = true
        
        reload()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        resultView.frame = resultView.frame.offsetBy(dx: 0, dy: resultView.frame.height)
        animate(visible: true)
        view.isHidden = false
    }
    
    func animate(visible:Bool)
    {
        let frame = resultView.frame
        let bottom = CGRect(origin: CGPoint(x: 0, y: view.frame.height), size: frame.size)
        let top = bottom.offsetBy(dx: 0, dy: -frame.height)
        
        let to = visible ? top : bottom
        UIView.animate(withDuration: 0.3, animations:
        {
            self.resultView.frame = to
        }, completion:
        {
            if $0 && !visible
            {
                self.dismiss(animated: true, completion: nil)
            }
        })
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
