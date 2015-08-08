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
    class ArgumentOption
    {
        let name:String, abbr:String, help:String, hasValue:Bool, trigger:()->Void
        var value:String?
        
        init(name:String, abbr:String, help:String, hasValue:Bool, trigger:()->Void)
        {
            self.name = name
            self.abbr = abbr
            self.help = help
            self.hasValue = hasValue
            self.trigger = trigger
        }
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
        if name == "" && abbr == ""
        {
            return
        }
        
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
    
    func showHelpMessage(stream:UnsafeMutablePointer<FILE> = stdout)
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
        
        fputs("Usage: urlcodec " + " ".join(abbrs) + " String ...\n", stream)
        
        for i in 0 ..< options.count
        {
            let item = options[i]
            var help = padding(item.abbr, length: maxAbbrLength)
            help += item.name == "" || item.abbr == "" ? " " : ","
            help += " " + padding(item.name, length: maxNameLength) + "\t" + item.help
            fputs(help + "\n", stream)
        }
    }
}
