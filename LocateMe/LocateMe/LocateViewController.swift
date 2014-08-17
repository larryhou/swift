//
//  LocateViewController.swift
//  LocateMe
//
//  Created by doudou on 8/17/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import Foundation
import UIKit

class LocateViewController:UITableViewController, SetupSettingReceiver
{
    private var setting:LocateSettingInfo!
    
    func setupSetting(setting: LocateSettingInfo)
    {
        self.setting = setting
    }
    
    override func viewWillAppear(animated: Bool)
    {
        println(setting)
    }
}
