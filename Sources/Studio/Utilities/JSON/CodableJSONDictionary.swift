//
//  CodableJSONDictionary.swift
//  Suite
//
//  Created by Ben Gottlieb on 2/22/24.
//

import Foundation

public struct CodableJSONDictionary: Codable, Equatable, Hashable, Sendable {
	public static func == (lhs: CodableJSONDictionary, rhs: CodableJSONDictionary) -> Bool {
		compareTwoJSONDictionaries(lDictionary: lhs.backing, rDictionary: rhs.backing)
	}
	
	public var dictionary: [String: Any] { backing }
	public static var dataKeyNames: [String] = []
	
	public init() { backing = [:] }
	public static var empty = CodableJSONDictionary()
	
	public subscript(key: String) -> Any? {
		get { backing[key] }
		set {
			if let newValue, !isJSON(newValue) { dlogg("Trying to assign a non-JSON value: \(key): \(newValue)") }
			backing[key] = newValue
		}
	}
	
	public func hash(into hasher: inout Hasher) {
		for (key, value) in dictionary {
			hasher.combine(key)
			if let hash = value as? any Hashable {
				hasher.combine(hash)
			}
		}
	}
	
	var backing: [String: any Sendable]
	
	public init(_ json: [String: Any]) {
		backing = json.filter { key, value in
			value is JSONDataType
		}
	}
	
	public init?(_ json: [String: Any]?) {
		guard let json else { return nil }
		self.init(json)
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: JSONCodingKey.self)
		
		backing = try container.decodeJSONDictionary()
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: JSONCodingKey.self)
		try container.encode(backing)
	}
}

extension CodableJSONDictionary: ExpressibleByDictionaryLiteral {
	public init(dictionaryLiteral elements: (String, Any)...) {
		let dict = elements.reduce(into: [:]) { $0[$1.0] = $1.1 }
		
		self.init(dict)
	}
}

struct JSONCodingKey: CodingKey {
	let string: String?
	let int: Int?

	init?(stringValue key: String) { string = key; int = nil }
	init?(intValue: Int) { int = intValue; string = nil }

	var stringValue: String { string ?? "\(int!)" }
	var intValue: Int? { int ?? Int(string ?? "0") ?? 0 }
}

