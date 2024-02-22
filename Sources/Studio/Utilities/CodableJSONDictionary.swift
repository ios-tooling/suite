//
//  CodableJSONDictionary.swift
//  Suite
//
//  Created by Ben Gottlieb on 2/22/24.
//

import Foundation

struct JSONCodingKey: CodingKey {
	let string: String?
	let int: Int?
	init?(stringValue key: String) { string = key; int = nil }
	var stringValue: String { string ?? "\(int!)" }
	var intValue: Int? { int ?? Int(string ?? "0") ?? 0 }
	init?(intValue: Int) { int = intValue; string = nil }
}

public struct CodableJSONDictionary: Codable, Equatable {
	public static func == (lhs: CodableJSONDictionary, rhs: CodableJSONDictionary) -> Bool {
		compareTwoJSONDictionaries(lDictionary: lhs.backing, rDictionary: rhs.backing)
	}
	
	var backing: [String: Any]
	
	public init?(_ json: [String: Any]?) {
		guard let json else { return nil }
		backing = json
	}
	
	public init(from decoder: Decoder) {
		backing = [:]
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: JSONCodingKey.self)
		try backing.encode(to: &container)
	}
}

extension [String: Any] {
	func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601) throws {
		for key in self.keys.sorted() {
			let value = self[key]
			guard let codingKey = JSONCodingKey(stringValue: key) else { continue }
			
			if let int = value as? Int {
				try container.encode(int, forKey: codingKey)
			} else if let string = value as? String {
				try container.encode(string, forKey: codingKey)
			} else if let float = value as? Float {
				try container.encode(float, forKey: codingKey)
			} else if let double = value as? Double {
				try container.encode(double, forKey: codingKey)
			} else if let date = value as? Date {
				try dateEncodingStrategy.encode(date: date, in: &container, key: codingKey)
			} else if let data = value as? Data {
				try container.encode(data.base64EncodedString(), forKey: codingKey)
			} else if let dict = value as? [String: Any] {
				var subContainer = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: codingKey)
				try dict.encode(to: &subContainer, dateEncodingStrategy: dateEncodingStrategy)
			} else if let array = value as? [Any] {
				var subContainer = container.nestedUnkeyedContainer(forKey: codingKey)
				try array.encode(to: &subContainer, dateEncodingStrategy: dateEncodingStrategy)
			}
		}
	}
}

extension [Any] {
	func encode(to container: inout UnkeyedEncodingContainer, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601) throws {
		for index in self.indices {
			let value = self[index]
			
			if let int = value as? Int {
				try container.encode(int)
			} else if let string = value as? String {
				try container.encode(string)
			} else if let float = value as? Float {
				try container.encode(float)
			} else if let double = value as? Double {
				try container.encode(double)
			} else if let date = value as? Date {
				try dateEncodingStrategy.encode(date: date, in: &container)
			} else if let data = value as? Data {
				try container.encode(data.base64EncodedString())
			} else if let dict = value as? [String: Any] {
				var subContainer = container.nestedContainer(keyedBy: JSONCodingKey.self)
				try dict.encode(to: &subContainer, dateEncodingStrategy: dateEncodingStrategy)
			} else if let array = value as? [Any] {
				try array.encode(to: &container, dateEncodingStrategy: dateEncodingStrategy)
			}
		}
	}
}

extension JSONEncoder.DateEncodingStrategy {
	func encode(date: Date, in container: inout UnkeyedEncodingContainer) throws {
		switch self {
		case .deferredToDate, .secondsSince1970:
			try container.encode(date.timeIntervalSince1970)
		case .millisecondsSince1970:
			try container.encode(date.timeIntervalSince1970 * 1000)
		case .iso8601:
			try container.encode(ISO8601DateFormatter().string(from: date))
		case .formatted(let formatter):
			try container.encode(formatter.string(from: date))
		case .custom:
			print("Failed to encode date using \(self)")
		@unknown default:
			print("Failed to encode date using \(self)")
		}
	}
	
	func encode(date: Date, in container: inout KeyedEncodingContainer<JSONCodingKey>, key: JSONCodingKey) throws {
		switch self {
		case .deferredToDate, .secondsSince1970:
			try container.encode(date.timeIntervalSince1970, forKey: key)
		case .millisecondsSince1970:
			try container.encode(date.timeIntervalSince1970 * 1000, forKey: key)
		case .iso8601:
			try container.encode(ISO8601DateFormatter().string(from: date), forKey: key)
		case .formatted(let formatter):
			try container.encode(formatter.string(from: date), forKey: key)
		case .custom:
			print("Failed to encode date using \(self)")
		@unknown default:
			print("Failed to encode date using \(self)")
		}
	}
}
