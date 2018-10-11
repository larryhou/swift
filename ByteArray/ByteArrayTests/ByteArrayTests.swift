//
//  ByteArrayTests.swift
//  ByteArrayTests
//
//  Created by larryhou on 5/20/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit
import XCTest

class ByteArrayTests: XCTestCase {
    func testReadBoolean() {
        var bytes = ByteArray()

        var value = UInt8(arc4random_uniform(2))
        bytes.data.appendBytes(&value, length: 1)

        bytes.position = 0
        XCTAssertEqual(bytes.readBoolean(), Bool(Int(value)))
    }

    func testReadInt8() {
        var bytes = ByteArray()
        for i in 0...0xFF {
            var byte = UInt8(arc4random_uniform(0xFF))
            var data = NSData(bytes: &byte, length: 1)

            var value: Int8 = 0
            data.getBytes(&value, length: 1)
            bytes.data.appendBytes(&value, length: 1)

            XCTAssertEqual(bytes.readInt8(), value)
        }
    }

    func testWriteInt() {
        let endian = ByteArray.Endian.LITTLE_ENDIAN

        var bytes = ByteArray()
        bytes.endian = endian

        for n in 0...5000 {
            var value = Int(arc4random())
            var position = Int(arc4random_uniform(UInt32(bytes.length)))

            bytes.position = position
            bytes.writeInt64(value)

            var num = 0
            bytes.data.getBytes(&num, range: NSRange(location: position, length: 8))
            if endian == .BIG_ENDIAN {
                XCTAssertEqual(value, num.bigEndian)
            } else {
                XCTAssertEqual(value, num)
            }
        }

    }

    func testReadInt() {
        let endian = ByteArray.Endian.BIG_ENDIAN

        var list: [Int] = []
        var data = NSMutableData()
        for n in 0...10000 {
            var value = Int(arc4random())

            list.append(value)
            if endian == .BIG_ENDIAN {
                value = value.bigEndian
            }

            data.appendBytes(&value, length: 8)
        }

        XCTAssertEqual(data.length % 8, 0)

        var bytes = ByteArray(data: data)
        bytes.endian = endian

        for n in 0...5000 {
            var index = Int(arc4random_uniform(UInt32(list.count)))

            bytes.position = index * 8
            XCTAssertEqual(list[index], bytes.readInt64())
        }
    }

    func testWriteInt8() {
        var value: Int8 = -25
        var bytes = ByteArray()
        bytes.writeInt8(value)

        bytes.position = 0
        XCTAssertEqual(value, bytes.readInt8())
    }

    func testWriteInt16() {
        var value: Int16 = -2500
        var bytes = ByteArray()
        bytes.endian = .BIG_ENDIAN
        bytes.writeInt16(value)

        bytes.position = 0
        XCTAssertEqual(value, bytes.readInt16())
    }

    func testWriteDouble() {
        let endian = ByteArray.Endian.LITTLE_ENDIAN

        var bytes = ByteArray()
        bytes.endian = endian

        for n in 0...5000 {
            var value = Double(arc4random()) / Double(UInt32.max)
            var position = Int(arc4random_uniform(UInt32(bytes.length)))

            bytes.position = position
            bytes.writeDouble(value)

            var num = 0.0
            if endian == .BIG_ENDIAN {
                var mem = [UInt8](count: 8, repeatedValue: 0)

                bytes.data.getBytes(&mem, range: NSRange(location: position, length: mem.count))
                num = UnsafePointer<Double>(mem.reverse()).memory
            } else {
                bytes.data.getBytes(&num, range: NSRange(location: position, length: 8))
            }

            XCTAssertEqual(value, num)
        }
    }

    func testReadDouble() {
        let endian = ByteArray.Endian.BIG_ENDIAN

        var list: [Double] = []
        var data = NSMutableData()
        for n in 0...10000 {
            var value = Double(arc4random()) / Double(UInt32.max)

            list.append(value)
            if endian == .BIG_ENDIAN {
                var mem = ByteArray.dump(value).reverse()
                value = UnsafePointer<Double>(mem).memory
            }

            data.appendBytes(&value, length: 8)
        }

        XCTAssertEqual(data.length % 8, 0)

        var bytes = ByteArray(data: data)
        bytes.endian = endian

        for n in 0...5000 {
            var index = Int(arc4random_uniform(UInt32(list.count)))

            bytes.position = index * 8
            XCTAssertEqual(list[index], bytes.readDouble())
        }
    }

    func testEndian() {
        var bytes = ByteArray()
        bytes.endian = .LITTLE_ENDIAN

        bytes.writeDouble(M_PI)

        var list = ByteArray.dump(M_PI)
        for i in 0..<bytes.length {
            XCTAssertEqual(list[i], bytes[i])
        }

        bytes.clear()
        bytes.endian = .BIG_ENDIAN
        bytes.writeDouble(M_PI)

        list = list.reverse()
        for i in 0..<bytes.length {
            XCTAssertEqual(list[i], bytes[i])
        }
    }

    func testWriteUTFBytes() {
        var text = "侯坤峰侯坤峰侯坤峰侯坤峰"

        var bytes = ByteArray()
        bytes.writeUTFBytes(text)

        var data = NSString(string: text).dataUsingEncoding(NSUTF8StringEncoding)!

        XCTAssertEqual(data.length, bytes.length)

        for i in 0..<data.length {
            var value: UInt8 = 0
            data.getBytes(&value, range: NSRange(location: i, length: 1))

            XCTAssertEqual(bytes[i], value)
        }
    }

    func testReadUTFBytes() {
        var text = "侯坤峰侯坤峰侯坤峰侯坤峰"

        var bytes = ByteArray()
        var data = NSString(string: text).dataUsingEncoding(NSUTF8StringEncoding)!
        bytes.data.appendData(data)

        bytes.position = 0
        XCTAssertEqual(text, bytes.readUTFBytes(data.length))
    }

    func testReadMultiBytes() {
        var text = "侯坤峰侯坤峰侯坤峰侯坤峰"

        var bytes = ByteArray()
        var encoding = CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
        var charset = CFStringConvertEncodingToNSStringEncoding(encoding)

        var data = NSString(string: text).dataUsingEncoding(charset)!
        bytes.data.appendData(data)

        bytes.position = 0
        XCTAssertEqual(text, bytes.readMultiByte(data.length, encoding: encoding))
    }

    func testWriteMultiBytes() {
        var text = "侯坤峰侯坤峰侯坤峰侯坤峰"
        var bytes = ByteArray()

        var encoding = CFStringEncoding(CFStringEncodings.EUC_TW.rawValue)
        bytes.writeMultiBytes(text, encoding: encoding)

        bytes.position = 0
        XCTAssertEqual(text, bytes.readMultiByte(bytes.length, encoding: encoding))
    }

    func testReadBytes() {
        var data = NSString(string: "侯坤峰侯坤峰侯坤峰侯坤峰").dataUsingEncoding(NSUTF8StringEncoding)!
        var bytes = ByteArray(data: data)

        var refer = ByteArray()

        var value = M_PI
        for n in 0...5000 {
            if n % 20 == 0 {
                refer.clear()
                refer.data.appendBytes(&value, length: sizeof(Double))
            }

            var bytesOffset = Int(arc4random_uniform(UInt32(bytes.length - 2)) + 1)
            var referOffset = Int(arc4random_uniform(UInt32(refer.length * 2)) + 1)

            var num = Int(arc4random_uniform(UInt32(data.length - bytesOffset)) + 1)

            bytes.position = bytesOffset
            bytes.readBytes(refer, offset: referOffset, length: num)

            for i in 0..<num {
                XCTAssertEqual(refer[i + referOffset], bytes[i + bytesOffset])
            }
        }
    }

    func testWriteBytes() {
        var data = NSString(string: "侯坤峰侯坤峰侯坤峰侯坤峰侯坤峰侯坤峰侯坤峰侯坤峰").dataUsingEncoding(NSUTF8StringEncoding)!
        var bytes = ByteArray(data: data)

        var refer = ByteArray()

        for n in 0...5000 {
            if n % 20 == 0 {
                refer.clear()
                refer.data.appendData(NSString(string: "larryhoularryhoularryhoularryhoularryhou").dataUsingEncoding(NSUTF8StringEncoding)!)
            }

            var referOffset = Int(arc4random_uniform(UInt32(refer.length - 2)) + 1)
            var bytesOFfset = Int(arc4random_uniform(UInt32(bytes.length)) + 1)

            var num = Int(arc4random_uniform(UInt32(refer.length - referOffset)) + 1)

            bytes.position = bytesOFfset
            bytes.writeBytes(refer, offset: referOffset, length: num)

            for i in 0..<num {
                XCTAssertEqual(bytes[i + bytesOFfset], refer[i + referOffset])
            }
        }
    }

    func testValueDump() {
        var value = M_PI

        var data = NSData(bytes: &value, length: sizeof(Double))

        var mem1 = ByteArray.dump(&value)
        var mem2 = ByteArray.dump(value)

        XCTAssertEqual(mem1.count, mem2.count)

        for i in 0..<mem1.count {
            var byte: UInt8 = 0
            data.getBytes(&byte, range: NSRange(location: i, length: 1))

            XCTAssertEqual(byte, mem1[i])
            XCTAssertEqual(mem1[i], mem2[i])
        }
    }

    func testPerformanceExample() {
        self.measureBlock {
            self.testReadBytes()
        }
    }

}
