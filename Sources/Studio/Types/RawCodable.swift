//
//  RawCodable.swift
//  
//
//  Created by Ben Gottlieb on 9/22/23.
//

import Foundation

public protocol CodableRepresentable: RawRepresentable<String> { }

extension CodableRepresentable where Self: Codable, RawValue == String {
	public var rawValue: String {
		do {
			let data = try JSONEncoder().encode(self)
			let string = String(data: data, encoding: .utf8)
			return string ?? ""
		} catch {
			print("Failed to encode: \(self), error: \(error)")
			return ""
		}
	}
	
	public init?(rawValue: String) {
		guard let data = rawValue.data(using: .utf8) else { return nil }
		guard let result = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
		self = result
	}
}

public protocol RawCodable: RawRepresentable, Codable, Identifiable where RawValue: Codable {
	
}

extension RawCodable {
	public var id: RawValue { rawValue }
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.rawValue)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let raw = try container.decode(RawValue.self)
		if let value = Self(rawValue: raw) {
			self = value
		} else {
			throw NSError()
		}
	}
}
