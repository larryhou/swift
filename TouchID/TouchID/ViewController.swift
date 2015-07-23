//
//  ViewController.swift
//  TouchID
//
//  Created by larryhou on 5/7/15.
//  Copyright © 2015 larryhou. All rights reserved.
//

import UIKit
import LocalAuthentication

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
    
    let SERVICE_PSSW = "LARRYHOU-PASSWORD-TEXT"
    let SERVICE_NAME = "TouchID.app"
    
    enum PickerComponent:Int
    {
        case Protection = 0, SACFlags
    }
    
    @IBOutlet weak var picker: UIPickerView!
    
    private var model:[[PickerItemInfo]]!
    
    override func viewWillAppear(animated: Bool)
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
        data.append(PickerItemInfo(label: "UserPresence", flags: SecAccessControlCreateFlags.UserPresence))
        data.append(PickerItemInfo(label: "TouchIDAny", flags: SecAccessControlCreateFlags.TouchIDAny))
        data.append(PickerItemInfo(label: "TouchIDCurrentSet", flags: SecAccessControlCreateFlags.TouchIDCurrentSet))
        data.append(PickerItemInfo(label: "DevicePasscode", flags: SecAccessControlCreateFlags.DevicePasscode))
        data.append(PickerItemInfo(label: "ApplicationPassword", flags: SecAccessControlCreateFlags.ApplicationPassword))
        model[PickerComponent.SACFlags.rawValue] = data
        
    }
    
    //MARK: UIPickerView
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int
    {
        return model.count
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return model[component].count
    }
    
//    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
//    {
//        return model[component][row].label
//    }
    
//    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString?
//    {
//        let text:String = model[component][row].label
//        
//        let format:[String:AnyObject] = [NSFontAttributeName:UIFont.systemFontOfSize(12)]
//        return NSAttributedString(string: text, attributes: format)
//    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView
    {
        var labelView:UILabel
        if view != nil
        {
            labelView = view as! UILabel
        }
        else
        {
            labelView = UILabel()
            labelView.font = UIFont.systemFontOfSize(20)
            labelView.textAlignment = NSTextAlignment.Center
        }
        
        labelView.text = model[component][row].label
        return labelView
    }
    
    func getComponentItemInfo(component:Int)->PickerItemInfo
    {
        let row = picker.selectedRowInComponent(component)
        return model[component][row]
    }
    
    //MARK: IBActions
    
    @IBAction func actionUpdatePassword(sender: UIButton)
    {
        resetPassword()
        
        let protection = getComponentItemInfo(PickerComponent.Protection.rawValue).protection
        let flags = getComponentItemInfo(PickerComponent.SACFlags.rawValue).flags
        
        var error:Unmanaged<CFErrorRef>?
        let sac = SecAccessControlCreateWithFlags(kCFAllocatorDefault, protection, flags, &error)
        if error != nil || sac == nil
        {
            print(error)
            return
        }
        
        var data:[String:AnyObject] = [:]
        data[kSecClass as String] = kSecClassGenericPassword
        data[kSecAttrService as String] = SERVICE_NAME
        data[kSecValueData as String] = SERVICE_PSSW.dataUsingEncoding(NSUTF8StringEncoding)!
        data[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIAllow
        data[kSecAttrAccessControl as String] = sac
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
        {
            var result:AnyObject?
            let status = SecItemAdd(data, &result)
            
            print("add: " + self.status2string(status))
            
            let alert = UIAlertController(title: "status", message: self.status2string(status), preferredStyle: UIAlertControllerStyle.ActionSheet)
            let action = UIAlertAction(title: "我知道了", style: UIAlertActionStyle.Cancel)
            { (target:UIAlertAction) in
                
            }
            
            alert.addAction(action)
            dispatch_async(dispatch_get_main_queue())
            {
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func actionReadPassword(sender: UIButton)
    {
        var query:[String:AnyObject] = [:]
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = SERVICE_NAME
        query[kSecReturnData as String] = true
        query[kSecUseOperationPrompt as String] = "读取Keychain密码"
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
        {
            var result:AnyObject?
            let status = SecItemCopyMatching(query, &result)
            
            print("match: " + self.status2string(status))
            
            var message:String = self.status2string(status)
            if status == errSecSuccess
            {
                let pssw = result as! NSData
                message += ": " + (NSString(data: pssw, encoding: NSUTF8StringEncoding) as! String)
            }
            
            let alert = UIAlertController(title: "status", message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
            let action = UIAlertAction(title: "我知道了", style: UIAlertActionStyle.Cancel)
            { (target:UIAlertAction) in
                    
            }
            
            alert.addAction(action)
            dispatch_async(dispatch_get_main_queue())
            {
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    func resetPassword()
    {
        var query:[String:AnyObject] = [:]
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = SERVICE_NAME
        
        let status = SecItemDelete(query)
        print("reset: " + status2string(status))
    }
    
    func status2string(status:OSStatus)->String
    {
        switch status
        {
            case errSecAllocate:
                return "Failed to allocate memory"
                
            case errSecAuthFailed:
                return "The user name or passphrase you entered is not correct"
                
            case errSecDecode:
                return "Unable to decode the provided data"
                
            case errSecDuplicateItem:
                return "The specified item already exists in the keychain"
                
            case errSecInteractionNotAllowed:
                return "User interaction is not allowed"
                
            case errSecItemNotFound:
                return "The specified item could not be found in the keychain"
                
            case errSecNotAvailable:
                return "No keychain is available. You may need to restart your"
                
            case errSecParam:
                return "One or more parameters passed to a function where not valid"
                
            case errSecSuccess:
                return "success"
            
            case OSStatus(errSecUserCanceled):
                return "User canceled the operation"
        
            case errSecUnimplemented:
                return "Function or operation not implemented"
                
            default:return "Unknown:\(status)"
        }
    }

    
    func unlockWithTouchID()
    {
        let context = LAContext()
        let policy = LAPolicy.DeviceOwnerAuthentication
        
        do
        {
            try context.canEvaluatePolicy(policy)
        }
        catch let error
        {
            print(error)
            return
        }
        
        let reason = "指纹解锁应用"
        context.evaluatePolicy(policy, localizedReason: reason)
        { flag, error in
            print(flag)
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

