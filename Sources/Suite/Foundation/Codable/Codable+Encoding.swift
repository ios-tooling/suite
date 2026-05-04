//
//  Codable+Encoding.swift
//  Suite
//
//  Created by ben on 9/9/19.
//

import Foundation

public extension Encodable {
	var stringValue: String? {
		stringValue(from: JSONEncoder.default)
	}

	var prettyJSON: String? {
		do {
			let encoder = JSONEncoder()
			encoder.dateEncodingStrategy = .custom { date, encoder in
				var container = encoder.singleValueContainer()

				if #available(iOS 15.0, macOS 12, watchOS 9, tvOS 15, *) {
					try container.encode(date.formatted())
				} else {
					try container.encode(date.localTimeString())
				}
			}
			encoder.outputFormatting = .prettyPrinted
			let json = try encoder.encode(self)
			return String(data: json, encoding: .utf8)
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
		if #available(iOS 15.0, macOS 12, watchOS 8, tvOS 15, *) {
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
