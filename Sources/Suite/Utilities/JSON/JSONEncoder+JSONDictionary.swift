//
//  JSONEncoder+JSONDictionary.swift
//
//
//  Created by Ben Gottlieb on 2/22/24.
//

import Foundation
import OSLog

@available(iOS 14.0, macOS 11.0, *)
fileprivate let logger = Logger(subsystem: "suite", category: "JSONEncoding")

extension KeyedEncodingContainer where K == JSONCodingKey {
	mutating func encode(_ dictionary: [String: Any], dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601) throws {
		for key in dictionary.keys.sorted() {
			let value = dictionary[key]
			guard let codingKey = JSONCodingKey(stringValue: key) else { continue }
			
			if let bool = value as? Bool {
				try encode(bool, forKey: codingKey)
			} else if let int = value as? Int {
				try encode(int, forKey: codingKey)
			} else if let string = value as? String {
				try encode(string, forKey: codingKey)
			} else if let float = value as? Float {
				try encode(float, forKey: codingKey)
			} else if let double = value as? Double {
				try encode(double, forKey: codingKey)
			} else if let date = value as? Date {
				try encode(date: date, using: dateEncodingStrategy, forKey: codingKey)
			} else if let data = value as? Data {
				try encode(data.base64EncodedString(), forKey: codingKey)
			} else if let dict = value as? [String: Any] {
				var subContainer = nestedContainer(keyedBy: JSONCodingKey.self, forKey: codingKey)
				try subContainer.encode(dict, dateEncodingStrategy: dateEncodingStrategy)
			} else if let array = value as? [Any] {
				var subContainer = nestedUnkeyedContainer(forKey: codingKey)
				try subContainer.encode(array)
			}
		}
	}
	
	mutating func encode(date: Date, using strategy: JSONEncoder.DateEncodingStrategy, forKey key: JSONCodingKey) throws {
		switch strategy {
		case .deferredToDate, .secondsSince1970:
			try encode(date.timeIntervalSince1970, forKey: key)
		case .millisecondsSince1970:
			try encode(date.timeIntervalSince1970 * 1000, forKey: key)
		case .iso8601:
			try encode(ISO8601DateFormatter().string(from: date), forKey: key)
		case .formatted(let formatter):
			try encode(formatter.string(from: date), forKey: key)
		case .custom:
			if #available(iOS 14.0, macOS 11.0, *) {
				logger.error("Failed to encode date using \(String(describing: strategy))")
			}
		@unknown default:
			if #available(iOS 14.0, macOS 11.0, *) {
				logger.error("Failed to encode date using \(String(describing: strategy))")
			}
		}
	}
}

extension UnkeyedEncodingContainer {
	mutating func encode(_ array: [Any], dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601) throws {
		for value in array {
			if let bool = value as? Bool {
				try self.encode(bool)
			} else if let int = value as? Int {
				try self.encode(int)
			} else if let string = value as? String {
				try self.encode(string)
			} else if let float = value as? Float {
				try self.encode(float)
			} else if let double = value as? Double {
				try self.encode(double)
			} else if let date = value as? Date {
				try encode(date: date, using: dateEncodingStrategy)
			} else if let data = value as? Data {
				try self.encode(data.base64EncodedString())
			} else if let dict = value as? [String: Any] {
				var subContainer = self.nestedContainer(keyedBy: JSONCodingKey.self)
				try subContainer.encode(dict, dateEncodingStrategy: dateEncodingStrategy)
			} else if let childArray = value as? [Any] {
				var subContainer = nestedUnkeyedContainer()
				try subContainer.encode(childArray)
			}
		}
	}
	
	mutating func encode(date: Date, using strategy: JSONEncoder.DateEncodingStrategy) throws {
		switch strategy {
		case .deferredToDate, .secondsSince1970:
			try encode(date.timeIntervalSince1970)
		case .millisecondsSince1970:
			try encode(date.timeIntervalSince1970 * 1000)
		case .iso8601:
			try encode(ISO8601DateFormatter().string(from: date))
		case .formatted(let formatter):
			try encode(formatter.string(from: date))
		case .custom:
			if #available(iOS 14.0, macOS 11.0, *) {
				logger.error("Failed to encode date using \(String(describing: strategy))")
			}
		@unknown default:
			if #available(iOS 14.0, macOS 11.0, *) {
				logger.error("Failed to encode date using \(String(describing: strategy))")
			}
		}
	}
}

