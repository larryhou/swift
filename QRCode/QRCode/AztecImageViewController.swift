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
        aztecImageView.layer.borderColor = UIColor(white: 0.9, alpha: 1.0).cgColor
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        aztecImageView.inputCompactStyle = compactStyleSwitch.isOn
    }
    
    @IBAction func compactStyleDidChange(_ sender: UISwitch)
    {
        aztecImageView.inputCompactStyle = sender.isOn
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
    
    func textViewDidChange(_ textView: UITextView)
    {
        aztecImageView.inputMessage = textView.text
        print(textView.text)
    }
}
