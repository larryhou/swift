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
        let label:String, value:SecAccessControlCreateFlags
    }
    
    let SERVICE_PSSW = "LARRYHOU-PASSWORD-TEXT"
    let SERVICE_NAME = "TouchID.app"
    
    @IBOutlet weak var picker: UIPickerView!
    
    private var sacFlags:[PickerItemInfo]!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        sacFlags = []
        sacFlags.append(PickerItemInfo(label: "UserPresence", value: SecAccessControlCreateFlags.UserPresence))
        sacFlags.append(PickerItemInfo(label: "TouchIDAny", value: SecAccessControlCreateFlags.TouchIDAny))
        sacFlags.append(PickerItemInfo(label: "TouchIDCurrentSet", value: SecAccessControlCreateFlags.TouchIDCurrentSet))
        sacFlags.append(PickerItemInfo(label: "DevicePasscode", value: SecAccessControlCreateFlags.DevicePasscode))
        sacFlags.append(PickerItemInfo(label: "ApplicationPassword", value: SecAccessControlCreateFlags.ApplicationPassword))
        unlockWithTouchID()
    }
    
    //MARK: UIPickerView
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return sacFlags.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return sacFlags[row].label
    }
    
    //MARK: IBActions
    
    @IBAction func actionUpdatePassword(sender: UIButton)
    {
        resetPassword()
        
        let row = picker.selectedRowInComponent(0)
        let flags = sacFlags[row].value
        
        var error:Unmanaged<CFErrorRef>?
        let sac = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, flags, &error)
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
        data[kSecAttrAccessControl as String] = sac.takeUnretainedValue()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
        {
            var result:Unmanaged<AnyObject>?
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
            var result:Unmanaged<AnyObject>?
            let status = SecItemCopyMatching(query, &result)
            
            print("match: " + self.status2string(status))
            
            var message:String = self.status2string(status)
            if status == errSecSuccess
            {
                let pssw = result!.takeUnretainedValue() as! NSData
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

