//
//  Codable.swift
//  Suite
//
//  Created by ben on 9/9/19.
//  Copyright © 2019 Stand Alone, Inc. All rights reserved.
//

import Foundation

enum SuiteDecodingError: Error, Sendable { case unknownKey(String), badString, jsonDecodeFailed, fileNotFound, noJSONValueFound }

public func isJSON(_ any: Any) -> Bool {
	if let dict = any as? [String: Any] {
		for (_, value) in dict { if !isJSON(value) { return false } }
		return true
	}

	if let array = any as? [Any] {
		for value in array { if !isJSON(value) { return false } }
		return true
	}
	return any is (any JSONDataType)
}

public protocol JSONExportable {
	func asJSON() throws -> JSONDictionary
}

public protocol PostDecodeAwakable: AnyObject {
	func awakeFromDecoder()
}

public class JSONExpandedDecoder: JSONDecoder, @unchecked Sendable {
	open override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
		let result = try super.decode(type, from: data)

		if let awakable = result as? PostDecodeAwakable {
			awakable.awakeFromDecoder()
		}
		return result
	}
}

public extension JSONDecoder {
	static let `default` = JSONDecoder()
}

@available(iOS 10.0, *)
public extension JSONDecoder {
	static let iso8601Decoder: JSONDecoder = {
		let decoder = JSONExpandedDecoder()
		decoder.dateDecodingStrategy = .expanded8601
		return decoder
	}()
}

extension String {
	var cleanedFromJSON: String {
		self.replacingOccurrences(of: "\\", with: "")
	}
}

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
