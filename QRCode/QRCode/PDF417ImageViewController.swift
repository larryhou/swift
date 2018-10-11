//
//  PDF417ImageViewController.swift
//  QRCode
//
//  Created by larryhou on 24/12/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import UIKit

class PDF417ImageViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate {
    struct CompactStyleInfo {
        let mode: Float, name: String
    }

    @IBOutlet weak var imageView: PDF417ImageView!

    @IBOutlet weak var aspectRatioSlider: UISlider!
    @IBOutlet weak var aspactRatioIndicator: UILabel!

    @IBOutlet weak var compactionModePicker: UIPickerView!

    @IBOutlet weak var compactStyleSwitch: UISwitch!
    @IBOutlet weak var alwaysSpecifyCompactionSwitch: UISwitch!

    private var styles: [CompactStyleInfo]!

    override func viewDidLoad() {
        super.viewDidLoad()

        styles = []
        styles.append(CompactStyleInfo(mode: 0, name: "Automatic"))
        styles.append(CompactStyleInfo(mode: 1, name: "Numeric"))
        styles.append(CompactStyleInfo(mode: 2, name: "Text"))
        styles.append(CompactStyleInfo(mode: 3, name: "Byte"))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        aspactRatioDidChange(aspectRatioSlider)
        alwaysSpecifyCompactionDidChange(alwaysSpecifyCompactionSwitch)
        compactStyleDidChange(compactStyleSwitch)
        compactionModePicker.selectRow(2, inComponent: 0, animated: false)
    }

    @IBAction func aspactRatioDidChange(_ sender: UISlider) {
        aspactRatioIndicator.text = String(format: "%2.0f", sender.value)
        imageView.inputPreferredAspectRatio = Float(sender.value)
    }

    @IBAction func compactStyleDidChange(_ sender: UISwitch) {
        imageView.inputCompactStyle = sender.isOn
    }

    @IBAction func alwaysSpecifyCompactionDidChange(_ sender: UISwitch) {
        imageView.inputAlwaysSpecifyCompaction = sender.isOn
    }

    // MARK: text
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }

        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        imageView.inputMessage = textView.text
    }

    // MARK: picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return styles.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return styles[row].name
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        imageView.inputCompactionMode = styles[row].mode
    }
}
