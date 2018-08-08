//
//  main.swift
//  iQRCode
//
//  Created by larryhou on 22/12/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import AppKit

extension String {
    var data: NSData? {
        return NSString(string: self).dataUsingEncoding(NSUTF8StringEncoding)
    }
}

var arguments = Process.arguments
arguments = Array(arguments[1..<arguments.count])

var verbose = false
var inputMessage = "", file: String?
var outputFile: String?

var size = 1024

let manager = ArgumentsManager(name: "iQRCode", usageAppending: "MESSAGE")
manager.insertOption("--input-message", abbr: "-m", help: "message for encoding", hasValue: true) {
    inputMessage = (manager.getOption("-m")?.value)!
}
manager.insertOption("--message-file", abbr: "-f", help: "message file for encoding", hasValue: true) {
    file = (manager.getOption("-f")?.value)!
}
manager.insertOption("--image-size", abbr: "-s", help: "image side length", hasValue: true) {
    size = NSString(string: (manager.getOption("-s")?.value)!).integerValue
}
manager.insertOption("--output-file", abbr: "-o", help: "image output file path for save", hasValue: true) {
    outputFile = (manager.getOption("-o")?.value)!
}

manager.insertOption("--verbose", abbr: "-v", help: "show verbose runtime message", hasValue: false) { verbose = true }
manager.insertOption("--help", abbr: "-h", help: "show help message", hasValue: false) {
    manager.showHelpMessage()
    exit(0)
}

while arguments.count > 0 {
    let text = arguments[0]
    if manager.recognizeOption(text, triggerWhenMatch: false) {
        let option = manager.getOption(text)!

        arguments.removeAtIndex(0)
        if option.hasValue {
            option.value = arguments.removeAtIndex(0)
            switch option.abbr {
                case "-m":
                    assert(option.value != nil && option.value != "", "INVALIDE MESSAGE")
                case "-s":
                    assert(option.value != nil, "INVALIDE SIZE VALUE")
                    let num = NSString(string: option.value!).integerValue
                    assert(num >= 10, "IMAGE SIZE LESS THAN 10")
                default:break
            }
        }

        option.trigger()
    } else {
        break
    }
}

func createQRImage(data: NSData, size: Int, path: String? = nil) {
    let filter = CIFilter(name: "CIQRCodeGenerator")
    filter?.setValue("L", forKey: "inputCorrectionLevel")
    filter?.setValue(data, forKey: "inputMessage")

    var ci_image = (filter?.outputImage)!
    let scale = CGFloat(size) / ci_image.extent.size.width
    ci_image = ci_image.imageByApplyingTransform(CGAffineTransformMakeScale(scale, scale))

    let cg_image = CIContext().createCGImage(ci_image, fromRect: ci_image.extent)
    let ns_image = NSImage(CGImage: cg_image, size: ci_image.extent.size)

    ns_image.lockFocus()
    let bitmap = NSBitmapImageRep(focusedViewRect: ci_image.extent)
    ns_image.unlockFocus()

    var properties: [String: AnyObject] = [:]
    properties["timestamp"] = NSDate().timeIntervalSince1970

    let bitmapData = bitmap?.representationUsingType(.NSPNGFileType, properties: properties)
    if let binary = bitmapData {
        let output_path: String
        if path == nil {
            let dir = NSSearchPathForDirectoriesInDomains(.DownloadsDirectory, .UserDomainMask, true).first!
            output_path = NSString(string: dir).stringByAppendingPathComponent("QR.png")
        } else {
            output_path = path!
        }

        binary.writeToFile(output_path, atomically: true)
    }
}

if verbose {
    print(Process.arguments)
}

if file != nil {
    let url = NSURL.fileURLWithPath(file!, isDirectory: false)

    var error: NSError?
    if url.checkResourceIsReachableAndReturnError(&error) {
        let data = NSData(contentsOfURL: url)
        createQRImage(data!, size: size, path: outputFile)
    } else {
        if error != nil && verbose {
            print((error?.description)!)
        }
    }
} else {
    assert(inputMessage != "", "NEED INPUT MESSAGE")
    if verbose {
        print("input:", inputMessage)
        print("size:", size)
    }

    createQRImage(inputMessage.data!, size: size, path: outputFile)
}
