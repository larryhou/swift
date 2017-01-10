//
//  RegisterViewController.swift
//  FirebaseBasicTraining
//
//  Created by Horacio Garza on 24/09/16.
//  Copyright © 2016 HGarz Studios. All rights reserved.
//

import UIKit
import Firebase
import KVNProgress

class RegisterViewController: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var nameField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    
    //MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = false
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    
    //MARK: IBActions
    
    
    @IBAction func registerOnFirebase(_ sender: AnyObject) {
        
        
        KVNProgress.show(withStatus: "Registering...")
        FIRAuth.auth()?.createUser(withEmail: emailField.text!, password: passwordField.text!, completion: {
            (FIRUser, Error) in
            
            if let _ = Error{
                KVNProgress.showError(withStatus: Error?.localizedDescription)
                return
            }else{
                KVNProgress.showSuccess(withStatus: "Registration Complete!, you can now login.")
                self.navigationController?.popViewController(animated: true)
                
                
            }
            
            
        })

    
        
    }
    @IBAction func onTapInView(_ sender: AnyObject) {
        
        self.view.endEditing(true)
    }
    
    @IBAction func editingDidBegin(_ sender: AnyObject) {
        
        var point = CGPoint()
        point.y = 10//50
        scrollView.setContentOffset(point, animated: true)
    }
    
    @IBAction func editingDidEnd(_ sender: AnyObject) {
        
        var point = CGPoint()
        point.y = scrollView.contentOffset.y - 70//50
        scrollView.setContentOffset(point, animated: true)
    }
    
}
