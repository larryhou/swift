//
//  ViewController.swift
//  QRCode
//
//  Created by larryhou on 21/12/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate
{

    @IBOutlet weak var inputQRView: QRImageView!
    @IBOutlet weak var inputTextView: UITextView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        inputTextView.layer.borderWidth = 1.0
        inputTextView.layer.borderColor = UIColor(white: 0.9, alpha: 1.0).CGColor
        
        inputQRView.layer.borderWidth = 1.0
        inputQRView.layer.borderColor = UIColor(white: 0.9, alpha: 1.0).CGColor
    }
    
    func textViewDidChange(textView: UITextView)
    {
        inputQRView.inputMessage = textView.text
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}