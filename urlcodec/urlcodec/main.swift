//
//  main.swift
//  urlcodec
//
//  Created by larryhou on 31/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import Darwin

var arguments = Process.arguments
arguments.removeAtIndex(0)

struct ArgumentOption
{
    let name:String, abbr:String, description:String, trigger:()->Void
}

func padding(var value:String, length:Int) -> String
{
    while NSString(string: value).length < length
    {
        value += " "
    }
    
    return value
}

var decodeMode = true, verbose = false

var options:[ArgumentOption] = []
options.append(ArgumentOption(name: "--encode-mode", abbr: "-e", description: "Use url encode mode to process", trigger:{ decodeMode = false }))
options.append(ArgumentOption(name: "--decode-mode", abbr: "-d", description: "Use url decode mode to process", trigger:{ decodeMode = true }))
options.append(ArgumentOption(name: "--verbose", abbr: "-v", description: "Enable verbose printing", trigger:{ verbose = true }))
options.append(ArgumentOption(name: "--help", abbr: "-h", description: "Show help message", trigger:{
    
    var length = 0
    for item in options
    {
        length = max(length, NSString(string: item.name + item.abbr).length + 2)
    }
    
    for item in options
    {
        var name = "\(item.abbr),\(item.name)"
        print(padding(name, length: length) + "\t" + item.description)
    }
    exit(0)
}))

var map:[String:ArgumentOption] = [:]
for item in options
{
    map.updateValue(item, forKey: item.name)
    map.updateValue(item, forKey: item.abbr)
}

let regex = try NSRegularExpression(pattern: "-[a-z]|--[a-z_-]{2,}", options: NSRegularExpressionOptions.CaseInsensitive)

while arguments.count > 0
{
    let text = arguments[0]
    let matches = regex.matchesInString(text,
        options: NSMatchingOptions.ReportProgress,
        range: NSRange(location: 0, length: NSString(string: text).length))
    if matches.count == 1
    {
        arguments.removeAtIndex(0)
        map[text]?.trigger()
    }
    else
    {
        break
    }
}

if verbose
{
    print(Process.arguments)
}

if arguments.count > 0
{
    while arguments.count > 0
    {
        var text = arguments.removeAtIndex(0)
        if decodeMode
        {
            text = text.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        }
        else
        {
            text = text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        }
        
        print(text)
    }
}
else
{
    fputs("No Strings To Codec!\n", stderr)
    exit(1)
}


