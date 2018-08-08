//
//  ViewController.swift
//  FirebaseBasicTraining
//
//  Created by Horacio Garza on 21/09/16.
//  Copyright © 2016 HGarz Studios. All rights reserved.
//

import UIKit
import KVNProgress
import Firebase

class ViewController: UIViewController {

    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var scrollView: UIScrollView!

    let USER = "1"
    let PASSWORD = "1"
    let MoveInY = 50

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.

        //Hides the navbar

        //Sets the scroll disable
        scrollView.isScrollEnabled = false

    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: IBActions
    @IBAction func login(_ sender: AnyObject) {

        //Scroll View

        KVNProgress.show(withStatus: "Loging in...")

        FIRAuth.auth()?.signIn(withEmail: emailField.text!, password: passwordField.text!, completion: {
            (_, Error) in

            if let _ = Error {
                KVNProgress.showError(withStatus: Error?.localizedDescription)
                return
            } else {
                self.performSegue(withIdentifier: "loginSegue", sender: nil)
               KVNProgress.showSuccess(withStatus: "Welcome Back 🙂")
            }
        })

    }

    @IBAction func onTapInView(_ sender: AnyObject) {

        self.view.endEditing(true)
    }

    @IBAction func editingDidBegin(_ sender: AnyObject) {

        var point = CGPoint()
        point.y = 50
        scrollView.setContentOffset(point, animated: true)
    }

    @IBAction func editingDidEnd(_ sender: AnyObject) {

        var point = CGPoint()
        point.y = scrollView.contentOffset.y - 50//50
        scrollView.setContentOffset(point, animated: true)
    }

}
