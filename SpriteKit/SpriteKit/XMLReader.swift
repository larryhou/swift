//
//  XMLReader.swift
//  XMLParse
//
//  Created by larryhou on 3/29/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import Foundation

@objc protocol XMLReaderDelegate {
	optional func reader(reader: XMLReader, dataKey key: String) -> String
	optional func reader(reader: XMLReader, parseErrorOccured error: NSError!)

	optional func readerDidStartDocument(reader: XMLReader)
	func readerDidFinishDocument(reader: XMLReader, data: NSDictionary, elapse: NSTimeInterval)
}

class XMLReader: NSObject, NSXMLParserDelegate {
	typealias XMLNodeObject = NSMutableDictionary
	typealias XMLNodeList = NSMutableArray

	private let DEFAULT_DATA_KEY = "$"

	private var _parser: NSXMLParser!
	private var _dataKey: String!

	private var _data: XMLNodeObject!
	private var _item: XMLNodeObject!
	private var _stack: [XMLNodeObject]!

	private var _delegate: XMLReaderDelegate?
	private var _timestamp: NSTimeInterval = -1

	// MARK: parsing XML
	func read(data: NSData, delegate: XMLReaderDelegate?) {
		_delegate = delegate
		_data = XMLNodeObject()
		_stack = []

		_item = nil

		_parser = NSXMLParser(data: data)
		_parser.delegate = self
		_parser.parse()
	}

	// MARK: XML handling
	func parserDidStartDocument(parser: NSXMLParser) {
		_timestamp = NSDate.timeIntervalSinceReferenceDate()

		let key = _delegate?.reader?(self, dataKey: DEFAULT_DATA_KEY)
		if key != nil {
			_dataKey = key
		} else {
			_dataKey = DEFAULT_DATA_KEY
		}

		_delegate?.readerDidStartDocument?(self)
	}

	func parserDidEndDocument(parser: NSXMLParser) {
		let elapse = NSDate.timeIntervalSinceReferenceDate() - _timestamp

		_delegate?.readerDidFinishDocument(self, data: _data, elapse: elapse)
		_delegate = nil

		_parser.delegate = nil
		_parser = nil

		_stack = nil
		_data = nil
		_item = nil
	}

	func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject: AnyObject]) {
		var proxy = _item == nil ? _data : _item

		if _item != nil {
			_stack.append(_item)
		}

		var item = XMLNodeObject()
		for (key, value) in attributeDict {
			item[key as! NSString] = value
		}

		let name = elementName as NSString

		if proxy[name] == nil {
            proxy[name] = XMLNodeList()
		}

        (proxy[name] as! XMLNodeList).addObject(item)
		_item = item
	}

	func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		if _stack.count > 0 {
			_item = _stack.removeLast()
		} else {
			_item = nil
		}
	}

	func parser(parser: NSXMLParser, foundCDATA CDATABlock: NSData) {
		_item[_dataKey] = CDATABlock
	}

	func parser(parser: NSXMLParser, foundComment comment: String?) {
		println((__FUNCTION__, comment))
	}

	func parser(parser: NSXMLParser, foundCharacters string: String?) {
        if string == nil {
            return
        }

		let trimmedCharacters = string!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
		if trimmedCharacters == "" && string != "" {
			return
		}

		if _item[_dataKey] == nil {
			_item[_dataKey] = string
		} else {
			_item[_dataKey] = (_item[_dataKey]! as! String) + string!
		}
	}

	func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
		println((__FUNCTION__, parseError))
		_delegate?.reader?(self, parseErrorOccured: parseError)
	}

	func parser(parser: NSXMLParser, foundIgnorableWhitespace whitespaceString: String) {
		println((__FUNCTION__, whitespaceString))
	}

	func parser(parser: NSXMLParser, foundProcessingInstructionWithTarget target: String, data: String?) {
		println((__FUNCTION__, target, data))
	}

	func parser(parser: NSXMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String) {
		println((__FUNCTION__, prefix, namespaceURI))
	}

	func parser(parser: NSXMLParser, didEndMappingPrefix prefix: String) {
		println((__FUNCTION__, prefix))
	}

	// MARK: DTD handling
	func parser(parser: NSXMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) {
		println((__FUNCTION__, attributeName, elementName, type, defaultValue))
	}

	func parser(parser: NSXMLParser, foundElementDeclarationWithName elementName: String, model: String) {
		println((__FUNCTION__, elementName, model))
	}

	func parser(parser: NSXMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?) {
		println((__FUNCTION__, name, publicID, systemID))
	}

	func parser(parser: NSXMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) {
		println((__FUNCTION__, name, value))
	}

	func parser(parser: NSXMLParser, foundUnparsedEntityDeclarationWithName name: String, publicID: String?, systemID: String?, notationName: String?) {
		println((__FUNCTION__, name, publicID, systemID, notationName))
	}

	func parser(parser: NSXMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?) {
		println((__FUNCTION__, name, publicID, systemID))
	}
}
