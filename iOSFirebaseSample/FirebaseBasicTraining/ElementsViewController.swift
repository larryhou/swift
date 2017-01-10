//
//  ElementsViewController.swift
//  FirebaseBasicTraining
//
//  Created by Horacio Garza on 24/09/16.
//  Copyright © 2016 HGarz Studios. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import KVNProgress

class ElementsViewController: UIViewController, UITableViewDataSource {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        
    }
    
    @IBAction func willLogout(_ sender: AnyObject) {
        KVNProgress.show(withStatus: "Logging out...")
        do{
            try FIRAuth.auth()?.signOut()
            //self.navigationController?.popViewController(animated: true)
            KVNProgress.showSuccess(withStatus: "Logged Out ☹️")
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }catch{
        
            KVNProgress.showError(withStatus: "Unknown Error")
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = "Hello guest 🙂"
        return cell
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
