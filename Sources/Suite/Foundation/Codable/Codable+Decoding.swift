//
//  Codable+Decoding.swift
//  Suite
//
//  Created by ben on 9/9/19.
//

import Foundation

extension Decodable {
	public static func loadJSON(data: Data?, using decoder: JSONDecoder = .default) throws -> Self {
		guard let data else { throw SuiteDecodingError.fileNotFound }
		return try decoder.decode(self, from: data)
	}

	public static func loadJSON(dictionary: [String: Any], using decoder: JSONDecoder = .default) throws -> Self {
		let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
		return try decoder.decode(Self.self, from: data)
	}

	public static func loadJSON(file url: URL?, using decoder: JSONDecoder = .default) throws -> Self {
		guard let url else { throw SuiteDecodingError.fileNotFound }
		let data = try Data(contentsOf: url)
		return try self.loadJSON(data: data, using: decoder)
	}

	public static func loadJSON(userDefaults key: String) throws -> Self {
		let data = UserDefaults.standard.data(forKey: key)
		return try self.loadJSON(data: data)
	}

	@available(iOS 10.0, *)
	public static func load(fromString string: String, using decoder: JSONDecoder = .default) throws -> Self {
		guard let data = string.data(using: .utf8) else { throw SuiteDecodingError.badString }
		return try decoder.decode(Self.self, from: data)
	}
}

public extension Data {
	func decodeJSON<Output: Decodable>() throws -> Output {
		try Output.loadJSON(data: self)
	}
}
