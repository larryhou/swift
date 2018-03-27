//
//  ViewController.swift
//  QRCode
//
//  Created by larryhou on 21/12/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import UIKit

class QRImageViewController: UIViewController, UITextViewDelegate
{

    @IBOutlet weak var inputQRView: QRImageView!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var levelControl:UISegmentedControl!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        inputTextView.layer.borderWidth = 1.0
        inputTextView.layer.borderColor = UIColor(white: 0.9, alpha: 1.0).cgColor
        inputTextView.text = ""
        
        inputQRView.layer.borderWidth = 1.0
        inputQRView.layer.borderColor = UIColor(white: 0.9, alpha: 1.0).cgColor
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        levelDidChange(levelControl)
    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        inputQRView.inputMessage = textView.text
    }
    
    @IBAction func levelDidChange(_ sender:UISegmentedControl)
    {
        switch sender.selectedSegmentIndex
        {
            case 1:
                inputQRView.inputCorrectionLevel = "M"
            case 2:
                inputQRView.inputCorrectionLevel = "Q"
            case 3:
                inputQRView.inputCorrectionLevel = "H"
            default:
                inputQRView.inputCorrectionLevel = "L"
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
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
