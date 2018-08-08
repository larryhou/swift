//
//  WindowController.swift
//  ColorPicker
//
//  Created by larryhou on 22/09/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()

        window?.backgroundColor = .white
        if let delegate = window?.contentViewController as? NSWindowDelegate {
            window?.delegate = delegate
        }
    }

}
