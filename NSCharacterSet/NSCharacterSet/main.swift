//
//  main.swift
//  NSCharacterSet
//
//  Created by larryhou on 8/8/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation

var arguments = Process.arguments
arguments = Array(arguments[1..<arguments.count])

var name = "URLHostAllowedCharacterSet"
var renderUnicodeAsText = false
var column = 16
var inverse = false
var verbose = false

let manager = ArgumentsManager()
manager.insertOption("--character-set", abbr: "-s", help: "Property name of NSCharacterSet class", hasValue: true) { name = manager.getOption("-s")!.value! }
manager.insertOption("--render-unicode", abbr: "-u", help: "Render unicode as text", hasValue: false) { renderUnicodeAsText = true }
manager.insertOption("--inverse", abbr: "-i", help: "Inverse current character set", hasValue: false) { inverse = true }
manager.insertOption("--verbose", abbr: "-v", help: "Enable verbose printing", hasValue: false) { verbose = true }
manager.insertOption("--hex-columns", abbr: "-c", help: "Set hex columns in verbose printing", hasValue: true)
{
    let value = NSString(string: manager.getOption("-c")!.value!)
    column = max(1, value.integerValue)
}
manager.insertOption("--help", abbr: "-h", help: "Show help message", hasValue: false)
{
    manager.showHelpMessage()
    exit(0)
}

while arguments.count > 0
{
    let text = arguments[0]
    if manager.recognizeOption(text)
    {
        arguments.removeAtIndex(0)
        if var option = manager.getOption(text) where option.hasValue
        {
            let value = arguments[0]
            if manager.recognizeOption(value) == false
            {
                arguments.removeAtIndex(0)
                option.value = value
            }
            else
            {
                fputs("\(text): missing argument value\n", stderr)
                exit(1)
            }
        }
        
        manager.getOption(text)?.trigger()
    }
}
if verbose
{
    print("Arguments: \(Process.arguments)")
    print("NSCharacterSet.\(name)")
}

let valueObject = NSCharacterSet.valueForKeyPath(name)
if !(valueObject is NSCharacterSet)
{
    fputs("NSCharacterSet.\(name): not exist!", stderr)
    exit(2)
}

let bitmap:NSData
if inverse == false
{
    bitmap = (valueObject as! NSCharacterSet).bitmapRepresentation
}
else
{
    bitmap = (valueObject as! NSCharacterSet).invertedSet.bitmapRepresentation
}

for i in 0..<bitmap.length
{
    var byte = 0
    bitmap.getBytes(&byte, range: NSRange(location: i, length: 1))
    for n in 0..<8
    {
        let mask = 1 << n
        if (mask & byte) > 0
        {
            let unicode = i * 8 + n
            var message = String(format:"%04X  ", unicode)
            if renderUnicodeAsText
            {
                message.append(UnicodeScalar(unicode))
            }
            
            print(message)
        }
    }
}

if verbose
{
    for var i = 0; i < bitmap.length; i += column
    {
        var line = String(format:"%04X:  ", i)
        for n in i..<min(i+column, bitmap.length)
        {
            let position = NSRange(location: n, length: 1)
            
            var byte = 0
            bitmap.getBytes(&byte, range: position)
            line += String(format: "%02X ", byte)
            if (n + 1) % 4 == 0
            {
                line += " "
            }
        }
        
        print(line)
    }
    
    print("Total: \(bitmap.length)")
}