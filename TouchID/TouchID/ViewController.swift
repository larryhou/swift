//
//  ViewController.swift
//  TouchID
//
//  Created by larryhou on 5/7/15.
//  Copyright © 2015 larryhou. All rights reserved.
//

import UIKit
import LocalAuthentication
import Security

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource
{

    struct PickerItemInfo
    {
        let label:String
        let flags:SecAccessControlCreateFlags!, protection:CFString!
        init(label:String, flags:SecAccessControlCreateFlags)
        {
            self.label = label
            self.flags = flags
            self.protection = nil
        }
        
        init(label:String, protection:CFString)
        {
            self.label = label
            self.protection = protection
            self.flags = nil
        }
    }
    
    struct QueryParams
    {
        static let service = "TouchID.app"
        static let password = "LARRYHOU-PASSWORD-TEXT"
    }
    
    let background = DispatchQueue(label: "touchid")
    
    enum PickerComponent:Int
    {
        case Protection = 0, SACFlags = 1
    }
    
    @IBOutlet weak var picker: UIPickerView!
    
    private var model:[[PickerItemInfo]]!
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        unlockWithTouchID()
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        model = [[], []]
        
        var data:[PickerItemInfo] = []
        data.append(PickerItemInfo(label: "WhenUnlocked", protection: kSecAttrAccessibleWhenUnlocked))
        data.append(PickerItemInfo(label: "AfterFirstUnlock", protection: kSecAttrAccessibleAfterFirstUnlock))
        data.append(PickerItemInfo(label: "Always", protection: kSecAttrAccessibleAlways))
        data.append(PickerItemInfo(label: "WhenPasscodeSetThisDeviceOnly", protection: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly))
        data.append(PickerItemInfo(label: "WhenUnlockedThisDeviceOnly", protection: kSecAttrAccessibleWhenUnlockedThisDeviceOnly))
        data.append(PickerItemInfo(label: "AfterFirstUnlockThisDeviceOnly", protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly))
        data.append(PickerItemInfo(label: "AlwaysThisDeviceOnly", protection: kSecAttrAccessibleAlwaysThisDeviceOnly))
        model[PickerComponent.Protection.rawValue] = data
        
        data = []
        data.append(PickerItemInfo(label: "UserPresence", flags: SecAccessControlCreateFlags.userPresence))
        data.append(PickerItemInfo(label: "TouchIDAny", flags: SecAccessControlCreateFlags.touchIDAny))
        data.append(PickerItemInfo(label: "TouchIDCurrentSet", flags: SecAccessControlCreateFlags.touchIDCurrentSet))
        data.append(PickerItemInfo(label: "DevicePasscode", flags: SecAccessControlCreateFlags.devicePasscode))
        data.append(PickerItemInfo(label: "ApplicationPassword", flags: SecAccessControlCreateFlags.applicationPassword))
        model[PickerComponent.SACFlags.rawValue] = data
        
    }
    
    //MARK: UIPickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return model.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return model[component].count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        var labelView:UILabel
        if view != nil
        {
            labelView = view as! UILabel
        }
        else
        {
            labelView = UILabel()
            labelView.font = UIFont.systemFont(ofSize: 20)
            labelView.textAlignment = NSTextAlignment.center
        }
        
        labelView.text = model[component][row].label
        return labelView
    }
    
    func getComponentInfo(by component:Int)->PickerItemInfo
    {
        let row = picker.selectedRow(inComponent: component)
        return model[component][row]
    }
    
    //MARK: IBActions
    
    @IBAction func actionUpdatePassword(sender: UIButton)
    {
        resetPassword()
        
        let protection = getComponentInfo(by: PickerComponent.Protection.rawValue).protection
        let flags = getComponentInfo(by: PickerComponent.SACFlags.rawValue).flags
        
        var error:Unmanaged<CFError>?
        let sac = SecAccessControlCreateWithFlags(kCFAllocatorDefault, protection!, flags!, &error)
        if error != nil || sac == nil
        {
            print(error!)
            return
        }
        
        var data:[String:Any] = [:]
        data[kSecClass as String] = kSecClassGenericPassword
        data[kSecAttrService as String] = QueryParams.service
        data[kSecValueData as String] = QueryParams.password.data(using: String.Encoding.utf8)!
        data[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIAllow
        data[kSecAttrAccessControl as String] = sac
        
        background.async
        {
            var result:CFTypeRef?
            let status = SecItemAdd(data as CFDictionary, &result)
            self.showAlert(message: self.interpret(status: status))
        }
    }
    
    @IBAction func actionReadPassword(sender: UIButton)
    {
        var query:[String:Any] = [:]
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = QueryParams.service
        query[kSecReturnData as String] = true
        query[kSecUseOperationPrompt as String] = "读取Keychain密码"
        
        background.async
        {[unown, self]
            var result:AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            var message:String = self.interpret(status: status)
            if let result = result as? Data, status == errSecSuccess
            {
                if let data = String(data: result, encoding: String.Encoding.utf8)
                {
                    if status == errSecSuccess
                    {
                        message = data
                    }
                    else
                    {
                        message += ": " + data
                    }
                }
            }
            
            self.showAlert(message: message)
        }
    }
    
    func showAlert(message: String)
    {
        let alert = UIAlertController(title: "执行状态", message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "我知道了", style: .cancel, handler: nil))
        DispatchQueue.main.async
        {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func resetPassword()
    {
        var query:[String:Any] = [:]
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = QueryParams.service
        
        let status = SecItemDelete(query as CFDictionary)
        print("reset: " + interpret(status: status))
    }
    
    func interpret(status:OSStatus)->String
    {
        switch status
        {
            case errSecAllocate:
                return "Failed to allocate memory."
                
            case errSecAuthFailed:
                return "Authorization/Authentication failed."
                
            case errSecDecode:
                return "Unable to decode the provided data."
                
            case errSecDuplicateItem:
                return "The item already exists."
                
            case errSecInteractionNotAllowed:
                return "Interaction with the Security Server is not allowed."
                
            case errSecItemNotFound:
                return "The item cannot be found."
                
            case errSecNotAvailable:
                return "No trust results are available."
                
            case errSecParam:
                return "One or more parameters passed to the function were not valid."
                
            case errSecSuccess:
                return "sucess"
            
            case errSecUserCanceled:
                return "User canceled the operation"
        
            case errSecUnimplemented:
                return "Function or operation not implemented."
                
            default:return "Unknown:\(status)"
        }
    }

    
    func unlockWithTouchID()
    {
        let context = LAContext()
        let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        
        var error:NSError?
        if context.canEvaluatePolicy(policy, error: &error)
        {
            let reason = "指纹解锁应用"
            context.evaluatePolicy(policy, localizedReason: reason)
            { flag, error in
                var message = "指纹识别成功:\(flag)"
                if let error = error
                {
                    message += " error:\(error.localizedDescription)"
                }
                self.showAlert(message: message)
            }
        }
        else
        {
            print(error!)
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}

