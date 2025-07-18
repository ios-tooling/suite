//
//  JSONDecoder+JSONDictionary.swift
//  
//
//  Created by Ben Gottlieb on 2/22/24.
//

import Foundation

extension KeyedDecodingContainer where K == JSONCodingKey {
	func decodeJSONDictionary(dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) throws -> [String: Sendable] {
		var results: [String: Sendable] = [:]
		
		for key in allKeys {
			do {
				results[key.stringValue] = try decodeJSONValue(forKey: key)
			} catch {
				//we're going to eat this error for now, as it seems to indicate a null value.
			}
		}
		return results
	}
	
	func decodeJSONValue(forKey codingKey: JSONCodingKey, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) throws -> Sendable {
		if let string = try? decode(String.self, forKey: codingKey) {
			if let date = dateDecodingStrategy.date(from: string) { return date }
			if CodableJSONDictionary.dataKeyNames.contains(codingKey.stringValue), let data = Data(base64Encoded: string) { return data }
			return string
		}

		if let double = try? decode(Double.self, forKey: codingKey) {
			if let date = dateDecodingStrategy.date(from: double) { return date }
			return double
		}

		if let int = try? decode(Int.self, forKey: codingKey) {
			if let date = dateDecodingStrategy.date(from: int) { return date }
			return int
		}

		if let bool = try? decode(Bool.self, forKey: codingKey) { return bool }
		
		if let childContainer = try? nestedContainer(keyedBy: JSONCodingKey.self, forKey: codingKey) {
			return try childContainer.decodeJSONDictionary(dateDecodingStrategy: dateDecodingStrategy)
		}
		
		if var childContainer = try? nestedUnkeyedContainer(forKey: codingKey) {
			return try childContainer.decodeJSONArray(dateDecodingStrategy: dateDecodingStrategy)
		}
		
		throw SuiteDecodingError.noJSONValueFound
	}
}

extension UnkeyedDecodingContainer {
	mutating func decodeJSONArray(dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) throws -> [Sendable] {
		var results: [Sendable] = []
		guard let count = self.count else { return [] }
		
		for _ in 0..<count {
			if let value = try? decodeJSONValue(dateDecodingStrategy: dateDecodingStrategy) {
				results.append(value)
			}
		}
		return results
	}
	
	mutating func decodeJSONValue(dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) throws -> Sendable {
		if let string = try? decode(String.self) {
			if let date = dateDecodingStrategy.date(from: string) { return date }
			if let data = Data(base64Encoded: string) { return data }
			return string
		}

		if let int = try? decode(Int.self) {
			if let date = dateDecodingStrategy.date(from: int) { return date }
			return int
		}

		if let double = try? decode(Double.self) {
			if let date = dateDecodingStrategy.date(from: double) { return date }
			return double
		}

		if let bool = try? decode(Bool.self) { return bool }
		
		if let childContainer = try? nestedContainer(keyedBy: JSONCodingKey.self) {
			return try childContainer.decodeJSONDictionary(dateDecodingStrategy: dateDecodingStrategy)
		}
		
		if var childContainer = try? nestedUnkeyedContainer() {
			return try childContainer.decodeJSONArray(dateDecodingStrategy: dateDecodingStrategy)
		}
		
		throw SuiteDecodingError.noJSONValueFound
	}

}

extension JSONDecoder.DateDecodingStrategy {
	func date(from string: String) -> Date? {
		switch self {
		case .iso8601: ISO8601DateFormatter().date(from: string)
		case .formatted(let formatter): formatter.date(from: string)
		default: nil
		}
	}
	
	func date(from double: Double) -> Date? {
		nil
	}
	
	
	func date(from int: Int) -> Date? {
		nil
	}
}
