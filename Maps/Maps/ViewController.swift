//
//  ViewController.swift
//  Maps
//
//  Created by Horacio Garza on 20/08/16.
//  Copyright © 2016 HGarz Studios. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import KVNProgress
import Squeal

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtBirthday: UITextField!
    @IBOutlet weak var viewBirthday: UIView!

    @IBOutlet weak var datePicker: UIDatePicker!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.txtEmail.delegate = self
        //Abre la vista
        self.viewBirthday.removeFromSuperview()
        self.txtBirthday.inputView = self.viewBirthday

        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let currentDate = NSDate()
        let dateComponents = NSDateComponents()
        dateComponents.year = -13
        let minDate = calendar!.dateByAddingComponents(dateComponents, toDate: currentDate, options: NSCalendarOptions(rawValue: 0))
        self.datePicker.minimumDate = minDate

        KVNProgress.showWithStatus("Loading")
        Alamofire.request(.GET, "https://httpbin.org/get", parameters: ["foo": "bar"])
            .responseJSON { response in
                /*print(response.request)  // original URL request
                 print(response.response) // URL response
                 print(response.data)     // server data
                 print(response.result)   // result of response serialization*/

                if response.result.isSuccess {

                    KVNProgress.showWithStatus("Creating DB")

                    do {
                        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
                        let path = paths[0]
                        let db = try Database(path: "\(path)contacts.db")
                        try db.createTable("requests",
                            definitions: [
                                "id INTEGER PRIMARY KEY",
                                "parameter TEXT",
                                "VALUE TEXT"], ifNotExists: true)

                        let json = JSON(response.result.value!)
                        print(json)
                        for index in 0 ..< json["args"].count {

                            _ = try db.insertInto("requests",
                                values: [ "id": index,
                                    "parameter": String(json["args"]["foo"])
                                ])

                        }

                        print(try db.countFrom("requests").description)

                        let results = try db.prepareSelectFrom("requests", whereExpr: "id = ?", parameters: ["0"])

                        while try results.next() {
                            print(results.stringValue("parameter")!)
                        }

                    } catch let error as NSError {
                        print(error.localizedDescription)
                    }
                    KVNProgress.dismiss()

                } else {
                    KVNProgress.showErrorWithStatus(response.result.error?.localizedDescription)

                }

        }

    }

    @IBAction func datePickerValueChanged(sender: UIDatePicker) {

        let date: NSDateFormatter = NSDateFormatter()
        date.dateStyle = NSDateFormatterStyle.ShortStyle
        date.timeStyle = NSDateFormatterStyle.NoStyle

        let dateString = date.stringFromDate(sender.date)

        self.txtBirthday.text = dateString
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func closeBirthdayPicker(sender: AnyObject) {
        self.txtBirthday.resignFirstResponder()
    }
    func textFieldDidBeginEditing(textField: UITextField) {

        if textField == self.txtEmail {
            print("Empezando a editar email")
        } else {

            let txtP: UITextField = self.view.viewWithTag(10) as! UITextField

            if textField == txtP {
                print("Empezando a editar email")
            }
        }
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {

        if textField == txtEmail {
            (self.view.viewWithTag(10) as! UITextField).becomeFirstResponder()
        } else {
            self.view.endEditing(true)

        }

        return true
    }

    // MARK: 

    @IBAction func onOutsideTap(sender: AnyObject) {
        self.view.endEditing(true)

    }

}
