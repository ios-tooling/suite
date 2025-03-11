//
//  Codable+Additions.swift
//  Suite
//
//  Created by ben on 9/9/19.
//  Copyright © 2019 Stand Alone, Inc. All rights reserved.
//

import Foundation

public func isJSON(_ any: Any) -> Bool {
	if let dict = any as? [String: Any] {
		for (_, value) in dict { if !isJSON(value) { return false }}
		return true
	}

	if let array = any as? [Any] {
		for value in array { if !isJSON(value) { return false }}
		return true
	}
	return any is (any JSONDataType)
}

public extension Data {
	func decodeJSON<Output: Decodable>() throws -> Output {
		try Output.loadJSON(data: self)
	}
}

public extension JSONDictionary {
	var plist: PropertyListDictionary { self as? PropertyListDictionary ?? [:] }
}

extension Dictionary where Key == String {
	public var jsonDictionary: JSONDictionary {
		self.compactMapValues { value in
			value as? (any JSONDataType)
		}
	}
}

public protocol JSONExportable {
	func asJSON() throws -> JSONDictionary
}

public protocol PostDecodeAwakable: AnyObject {
	func awakeFromDecoder()
}

public class JSONExpandedDecoder: JSONDecoder, @unchecked Sendable {
	open override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
		let result = try super.decode(type, from: data)
		
		if let awakable = result as? PostDecodeAwakable {
			awakable.awakeFromDecoder()
		}
		return result
	}
}

public extension Dictionary where Key == String {
	var jsonData: Data {
		get throws {
			try JSONSerialization.data(withJSONObject: self)
		}
	}
	
	var title: String? {
		self["title"] as? String ?? self["name"] as? String ?? self["description"] as? String ?? self["desc"] as? String
	}
}

public extension Encodable {
	var stringValue: String? {
		stringValue(from: JSONEncoder.default)
	}
	
	var prettyJSON: String? {
		do {
			let encoder = JSONEncoder()
			encoder.dateEncodingStrategy = .custom { date, encoder in
				var container = encoder.singleValueContainer()
				
				if #available(iOS 15.0, macOS 12, *) {
					try container.encode(date.formatted())
				} else {
					try container.encode(date.localTimeString())
				}
			}
			encoder.outputFormatting = .prettyPrinted
			let json = try encoder.encode(self)
			let string = String(data: json, encoding: .utf8)
			return string
			//?.replacingOccurrences(of: "\\/", with: "/")
		} catch {
			return "error extracting JSON: \(error)"
		}
	}
	
	func logJSON() {
		if let json = prettyJSON {
			logg(json)
		}
	}
	
	func stringValue(from encoder: JSONEncoder) -> String? {
		guard let data = try? encoder.encode(self) else { return nil }
		
		return String(data: data, encoding: .utf8)
	}
	
	func asJSON(using encoder: JSONEncoder = .default) throws -> JSONDictionary {
		let data = try asJSONData(using: encoder)
		if #available(iOS 15.0, macOS 12, watchOS 8, *) {
			return try JSONSerialization.jsonObject(with: data, options: .topLevelDictionaryAssumed) as? JSONDictionary ?? [:]
		} else {
			return try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary ?? [:]
		}
	}
	
	func asJSONData(using encoder: JSONEncoder = .default) throws -> Data {
		try encoder.encode(self)
	}
	
	func saveJSON(to url: URL, using encoder: JSONEncoder = .default) throws {
		let data = try encoder.encode(self)
		try data.write(to: url, options: .atomic)
	}
	
	func saveJSON(toUserDefaults key: String, using encoder: JSONEncoder = .default) throws {
		let data = try encoder.encode(self)
		UserDefaults.standard.set(data, forKey: key)
	}
}

extension Decodable {
	public static func loadJSON(data: Data?, using decoder: JSONDecoder = .default) throws -> Self {
		guard let data = data else { throw JSONDecoder.DecodingError.fileNotFound }
		return try decoder.decode(self, from: data)
	}
	
	public static func loadJSON(dictionary: [String: Any], using decoder: JSONDecoder = .default) throws -> Self {
		let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
		return try decoder.decode(Self.self, from: data)
	}
	
	public static func loadJSON(file url: URL?, using decoder: JSONDecoder = .default) throws -> Self {
		guard let url = url else { throw JSONDecoder.DecodingError.fileNotFound }
		let data = try Data(contentsOf: url)
		return try self.loadJSON(data: data, using: decoder)
	}
	
	public static func loadJSON(userDefaults key: String) throws -> Self {
		let data = UserDefaults.standard.data(forKey: key)
		return try self.loadJSON(data: data)
	}
	
	@available(iOS 10.0, *)
	public static func load(fromString string: String, using decoder: JSONDecoder = .default) throws -> Self {
		guard let data = string.data(using: .utf8) else { throw JSONDecoder.DecodingError.badString }
		
		return try decoder.decode(Self.self, from: data)
	}
}

extension String {
	var cleanedFromJSON: String {
		return self.replacingOccurrences(of: "\\", with: "")
	}
}

public extension JSONEncoder {
	static let `default`: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [ .withoutEscapingSlashes, .prettyPrinted, .sortedKeys ]
		return encoder
	}()
}

@available(iOS 10.0, *)
public extension JSONEncoder {
	static let iso8601Encoder: JSONEncoder = {
		let encoder = JSONEncoder.default
		
		encoder.dateEncodingStrategy = .iso8601
		return encoder
	}()
}

public extension JSONDecoder {
	static let `default` = JSONDecoder()
	
	enum DecodingError: Error, Sendable { case unknownKey(String), badString, jsonDecodeFailed, fileNotFound }
}

@available(iOS 10.0, *)
public extension JSONDecoder {
	static let iso8601Decoder: JSONDecoder = {
		let decoder = JSONExpandedDecoder()
		
		decoder.dateDecodingStrategy = .expanded8601
		return decoder
	}()
}

@available(iOS 10.0, *)
public extension Encodable where Self: Decodable {
	func duplicate(using encoder: JSONEncoder = .iso8601Encoder, and decoder: JSONDecoder = .iso8601Decoder) throws -> Self {
		let data = try encoder.encode(self)
		return try decoder.decode(Self.self, from: data)
	}
}

public extension Decodable where Self: Encodable {
	func copyViaJSON(usingEncoder encoder: JSONEncoder = .default, decoder: JSONDecoder = .default) throws -> Self {
		let data = try encoder.encode(self)
		let result = try decoder.decode(Self.self, from: data)
		
		(result as? PostDecodeAwakable)?.awakeFromDecoder()
		
		return result
	}
}

//enum RawRepresentableError: Error { case unknownRawValue(Any.Type, String) }
//
//extension RawRepresentable where RawValue == String, Self: Codable {
//	public init(from decoder: Decoder) throws {
//		let container = try decoder.singleValueContainer()
//		let rawValue = try container.decode(String.self)
//
//		if let newValue = Self.init(rawValue: rawValue) {
//			self = newValue
//		} else {
//			throw RawRepresentableError.unknownRawValue(Self.self, rawValue)
//		}
//	}
//	
//	public func encode(to encoder: Encoder) throws {
//		var container = encoder.singleValueContainer()
//		try container.encode(rawValue)
//	}
//}

extension RawRepresentable where RawValue == Int, Self: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let rawValue = try container.decode(Int.self)
		do {
			self.init(rawValue: rawValue)!
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}
}
