//
//  Color+Codable.swift
//  
//
//  Created by Ben Gottlieb on 5/9/23.
//

import SwiftUI

@available(iOS 15.0, tvOS 14, macOS 11, watchOS 7, *)
extension Color: @retroactive Codable {
	enum ColorDecodeError: Error, Sendable { case unableToExtractColor }
	enum ColorEncodeError: Error, Sendable { case unableToExtractHex }
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()

		let hex = try container.decode(String.self)
		if let color = Color(hex: hex) {
			self = color
		} else {
			throw ColorDecodeError.unableToExtractColor
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()

		guard let hex else {
			throw ColorEncodeError.unableToExtractHex
		}
		try container.encode(hex)
	}
}
