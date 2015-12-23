//
//  AztecImageViewController.swift
//  QRCode
//
//  Created by larryhou on 22/12/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import UIKit

class AztecImageViewController:UIViewController, UITextViewDelegate
{
    @IBOutlet weak var aztecImageView: AztecImageView!
    @IBOutlet weak var compactStyleSwitch: UISwitch!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        aztecImageView.layer.borderWidth = 1.0
        aztecImageView.layer.borderColor = UIColor(white: 0.9, alpha: 1.0).CGColor
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        aztecImageView.inputCompactStyle = compactStyleSwitch.on
    }
    
    @IBAction func compactStyleDidChange(sender: UISwitch)
    {
        aztecImageView.inputCompactStyle = sender.on
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    {
        if text == "\n"
        {
            textView.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    func textViewDidChange(textView: UITextView)
    {
        aztecImageView.inputMessage = textView.text
    }
}
