//
//  ViewController.swift
//  ViewTransition
//
//  Created by larryhou on 25/08/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import UIKit

class TransitionOption {
    let label: String
    let value: UIViewAnimationOptions
    var enabled = false

    convenience init(label: String, value: UIViewAnimationOptions) {
        self.init(label: label, value: value, enabled: false)
    }

    init(label: String, value: UIViewAnimationOptions, enabled: Bool) {
        self.label = label
        self.value = value
        self.enabled = enabled
    }
}

class PickerController: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedItem?.enabled = false
        selectedItem = options[row]
        selectedItem?.enabled = true
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.font = UIFont(name: "Courier", size: 20)!
        label.text = options[row].label
        label.textAlignment = .center
        return label
    }

    weak var picker: UIPickerView?
    weak var label: UILabel?
    private(set) var options: [TransitionOption] = []
    private(set) var selectedItem: TransitionOption?

    func update(_ options: [TransitionOption]) {
        self.options = options
        picker?.dataSource = self
        picker?.delegate = self
        picker?.reloadComponent(0)
        for i in 0..<options.count {
            let item = options[i]
            if item.enabled {
                selectedItem = item
                picker?.selectRow(i, inComponent: 0, animated: false)
                label?.text = item.label
                break
            }
        }
    }
}

class PickerCell: UITableViewCell {
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var label: UILabel!

    var pickerController: PickerController?

    func update(_ options: [TransitionOption]) {
        if pickerController == nil {
            pickerController = PickerController()
            pickerController?.label = label
            pickerController?.picker = picker
        }
        pickerController?.update(options)
    }

    func select(_ value: Bool = false) {
        label.isHidden = value
        picker.isHidden = !label.isHidden
    }
}

class SwitchCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var checker: UISwitch!

    private(set) var data: TransitionOption?

    func update(_ data: TransitionOption) {
        self.data = data
        self.checker.isOn = data.enabled
        self.label.text = data.label
    }

    @IBAction func switchUpdate(_ sender: UISwitch) {
        data?.enabled = sender.isOn
    }
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var data: [Any] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        print(view.frame)

        data.append(TransitionOption(label: "layoutSubviews", value: .layoutSubviews))
        data.append(TransitionOption(label: "allowUserInteraction", value: .allowUserInteraction, enabled: true))
        data.append(TransitionOption(label: "beginFromCurrentState", value: .beginFromCurrentState))
        data.append(TransitionOption(label: "repeat", value: .repeat))
        data.append(TransitionOption(label: "autoreverse", value: .autoreverse))
        data.append(TransitionOption(label: "overrideInheritedDuration", value: .overrideInheritedDuration))
        data.append(TransitionOption(label: "overrideInheritedCurve", value: .overrideInheritedCurve))
        data.append(TransitionOption(label: "allowAnimatedContent", value: .allowAnimatedContent))
        data.append(TransitionOption(label: "showHideTransitionViews", value: .showHideTransitionViews))
        data.append(TransitionOption(label: "overrideInheritedOptions", value: .overrideInheritedOptions))

        var options: [TransitionOption] = []
        options.append(TransitionOption(label: "linear", value: .curveLinear, enabled: true))
        options.append(TransitionOption(label: "easeIn", value: .curveEaseIn))
        options.append(TransitionOption(label: "easeOut", value: .curveEaseOut))
        options.append(TransitionOption(label: "easeInOut", value: .curveEaseInOut))
        data.append(options)

        options = []
        options.append(TransitionOption(label: "flipFromLeft", value: .transitionFlipFromLeft, enabled: true))
        options.append(TransitionOption(label: "flipFromRight", value: .transitionFlipFromRight))
        options.append(TransitionOption(label: "flipFromTop", value: .transitionFlipFromTop))
        options.append(TransitionOption(label: "flipFromBottom", value: .transitionFlipFromBottom))
        options.append(TransitionOption(label: "crossDissolve", value: .transitionCrossDissolve))
        options.append(TransitionOption(label: "curlUp", value: .transitionCurlUp))
        options.append(TransitionOption(label: "curlDown", value: .transitionCurlDown))
        data.append(options)

        options = []
        options.append(TransitionOption(label: "fps60", value: .preferredFramesPerSecond60, enabled: true))
        options.append(TransitionOption(label: "fps30", value: .preferredFramesPerSecond30))
        data.append(options)

        tableView.reloadData()
    }

    @IBAction func presentTransition(_ sender: UIButton) {
        var options: UIViewAnimationOptions = []
        for entry in data {
            if entry is TransitionOption {
                let item = entry as! TransitionOption
                if item.enabled { options.insert(item.value) }
            } else {
                let list: [TransitionOption] = entry as! [TransitionOption]
                for item in list {
                    if item.enabled { options.insert(item.value) }
                }
            }
        }

        if let transitionController = storyboard?.instantiateViewController(withIdentifier: "ViewTransitionController") as? ViewTransitionController {
            transitionController.options = options
            present(transitionController, animated: true) {
                transitionController.startAnimation()
            }
        }

    }
    // MARK: table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = .clear
        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let selectedIndex = tableView.indexPathForSelectedRow {
            if selectedIndex.row == indexPath.row && data[indexPath.row] is [TransitionOption] {
                return 150
            }
        }
        return 70
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = data[indexPath.row]
        if item is TransitionOption {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as? SwitchCell {
                cell.update(item as! TransitionOption)
                return cell
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PickerCell") as? PickerCell {
                cell.update(item as! [TransitionOption])
                if let index = tableView.indexPathForSelectedRow, indexPath.row == index.row {
                    cell.select(true)
                } else {
                    cell.select(false)
                }
                return cell
            }
        }

        return UITableViewCell()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
