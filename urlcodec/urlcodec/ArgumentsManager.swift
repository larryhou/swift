//
//  ArgumentsManager.swift
//  urlcodec
//
//  Created by larryhou on 1/8/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation

class ArgumentsManager
{
    struct ArgumentOption
    {
        let name:String, abbr:String, help:String, hasValue:Bool, trigger:()->Void
    }
    
    private var map:[String:ArgumentOption]
    private var options:[ArgumentOption]
    
    private var pattern:NSRegularExpression!
    
    init()
    {
        self.options = []
        self.map = [:]
        
        do
        {
            pattern = try NSRegularExpression(pattern: "^-[a-z]+|--[a-z_-]{2,}$", options: NSRegularExpressionOptions.CaseInsensitive)
        }
        catch {}
    }
    
    func insertOption(name:String, abbr:String, help:String, hasValue:Bool, trigger:()->Void)
    {
        let argOption = ArgumentOption(name: name, abbr: abbr, help: help, hasValue: hasValue, trigger: trigger)
        options.append(argOption)
        
        map[name] = argOption
        map[abbr] = argOption
    }
    
    func getOption(name:String) -> ArgumentOption?
    {
        return map[name]
    }
    
    func recognizeOption(value:String, triggerWhenMatch:Bool = false) -> Bool
    {
        let matches = pattern.matchesInString(value,
            options: NSMatchingOptions.ReportProgress,
            range: NSRange(location: 0, length: NSString(string: value).length))
        if matches.count > 0
        {
            if triggerWhenMatch
            {
                trigger(value)
            }
            
            return true
        }
        
        return false
    }
    
    func trigger(name:String)
    {
        map[name]?.trigger()
    }
    
    func padding(var value:String, length:Int, var filling:String = " ") -> String
    {
        if NSString(string: filling).length == 0
        {
            filling = " "
        }
        else
        {
            filling = filling.substringToIndex(filling.startIndex.successor())
        }
        
        while NSString(string: value).length < length
        {
            value += filling
        }
        return value
    }
    
    func getHelpMessage(stdout:Bool = true) -> [String]
    {
        var maxNameLength = 0
        var maxAbbrLength = 0
        
        var abbrs:[String] = []
        for var i = 0; i < options.count; i++
        {
            maxNameLength = max(maxNameLength, NSString(string: options[i].name).length)
            maxAbbrLength = max(maxAbbrLength, NSString(string: options[i].abbr).length)
            abbrs.append(options[i].abbr)
        }
        
        var help:[String] = ["urlcodec " + " ".join(abbrs) + " String ..."]
        if stdout
        {
            print(help.last!)
        }
        
        for i in 0 ..< options.count
        {
            let item = options[i]
            var line = padding(item.abbr, length: maxAbbrLength)
            line += item.name == "" || item.abbr == "" ? " " : ","
            line += " " + padding(item.name, length: maxNameLength) + "\t" + item.help
            help.append(line)
            print(help.last!)
        }
        
        return help
    }
}
