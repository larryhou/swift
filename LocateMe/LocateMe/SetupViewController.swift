//
//  SetupViewController.swift
//  LocateMe
//
//  Created by doudou on 8/16/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

@objc protocol SetupSettingReceiver {
    func setupSetting(setting: LocateSettingInfo)
}

class LocateSettingInfo: NSObject {
    let accuracy: CLLocationAccuracy
    let sliderValue: Float

    init(accuracy: CLLocationAccuracy, sliderValue: Float) {
        self.accuracy = accuracy
        self.sliderValue = sliderValue
    }

    override var description: String {
        return super.description + "{accuracy:\(accuracy), sliderValue:\(sliderValue)}"
    }
}

class SetupViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    struct AccuracyOption {
        var label: String
        var value: CLLocationAccuracy
    }

    struct InitialSetupValue {
        let selectedIndex: Int
        let sliderValue: Float
    }

    @IBOutlet weak var accuracyPicker: UIPickerView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var label: UILabel!

    private var options: [AccuracyOption]!
    private var formater: NSNumberFormatter!
    private var selectedPickerIndex: Int!
    private var initial: InitialSetupValue!

    var setting: LocateSettingInfo {
        return LocateSettingInfo(accuracy: options[selectedPickerIndex].value, sliderValue: slider.value)
    }

    override func viewDidLoad() {
        options = []
        options.append(AccuracyOption(label: localizeString("AccuracyBest"), value: kCLLocationAccuracyBest))
        options.append(AccuracyOption(label: localizeString("Accuracy10"), value: kCLLocationAccuracyNearestTenMeters))
        options.append(AccuracyOption(label: localizeString("Accuracy100"), value: kCLLocationAccuracyHundredMeters))
        options.append(AccuracyOption(label: localizeString("Accuracy1000"), value: kCLLocationAccuracyKilometer))
        options.append(AccuracyOption(label: localizeString("Accuracy3000"), value: kCLLocationAccuracyThreeKilometers))

        formater = NSNumberFormatter()
        formater.minimumFractionDigits = 1
        formater.minimumIntegerDigits = 1

        initial = InitialSetupValue(selectedIndex: 2, sliderValue: slider.value)
        selectedPickerIndex = initial.selectedIndex
    }

    override func viewWillAppear(animated: Bool) {
        accuracyPicker.selectRow(selectedPickerIndex, inComponent: 0, animated: true)

        slider.value = setting.sliderValue
        sliderChangedValue(slider)
    }

    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        if segue.identifier == "SettingSegue" {
            if segue.destinationViewController is SetupSettingReceiver {
                var reciever: SetupSettingReceiver = segue.destinationViewController as SetupSettingReceiver
                reciever.setupSetting(setting)
            }
        }
    }

    @IBAction func reset(segue: UIStoryboardSegue) {
        accuracyPicker.selectRow(initial.selectedIndex, inComponent: 0, animated: true)

        slider.value = initial.sliderValue
        sliderChangedValue(slider)
    }

    @IBAction func sliderChangedValue(sender: UISlider) {
        label.text = formater.stringFromNumber(sender.value)
    }

    func numberOfComponentsInPickerView(pickerView: UIPickerView!) -> Int {
        return 1
    }

    func pickerView(pickerView: UIPickerView!, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }

    func pickerView(pickerView: UIPickerView!, titleForRow row: Int, forComponent component: Int) -> String! {
        return options[row].label
    }

    func pickerView(pickerView: UIPickerView!, didSelectRow row: Int, inComponent component: Int) {
        selectedPickerIndex = row
    }
}
