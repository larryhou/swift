//
//  logger.swift
//  ScreenRecording
//
//  Created by larryhou on 12/03/2018.
//  Copyright © 2018 larryhou. All rights reserved.
//

import Foundation

class debug {
    private static var formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss.SSS"
        return dateFormatter
    }()
    private static var stream: FileHandle? = {
        let location = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(FRAMEWORK_NAME).txt")
        do {
            if (FileManager.default.fileExists(atPath: location.path)) {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: location.path),
                    let usage = attributes[FileAttributeKey.size] as? Double {
                    if usage >= 1 * 1024 * 1024 // 1MB
                    {
                        try? FileManager.default.removeItem(at: location)
                    }
                }
            }

            if !FileManager.default.fileExists(atPath: location.path) {
                FileManager.default.createFile(atPath: location.path, contents: nil, attributes: nil)
            }

            return try FileHandle(forWritingTo: location)
        } catch {return nil}
    }()

    static func print(_ items: Any...) {
        let message = "\(debug.formatter.string(from: Date())) \(items.map({String(describing: $0)}).joined(separator: " "))"
        Swift.print(message)

        guard let stream = debug.stream else { return }
        stream.seekToEndOfFile()
        if let data = message.data(using: .utf8) {
            stream.write(data)
            stream.write(Data(bytes: [0x0A]))
        }
    }
}
