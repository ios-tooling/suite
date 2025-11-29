//
//  UUID.swift
//  Suite
//
//  Created by Ben Gottlieb on 11/29/25.
//

import Foundation

public extension UUID {
	static func v7() -> UUID {
		var uuid = UUID().uuid
		
		let timestamp = UInt64(Date().timeIntervalSince1970 * 1000.0)
		
		uuid.0 = UInt8((timestamp >> 40) & 0xFF)
		uuid.1 = UInt8((timestamp >> 32) & 0xFF)
		uuid.2 = UInt8((timestamp >> 24) & 0xFF)
		uuid.3 = UInt8((timestamp >> 16) & 0xFF)
		uuid.4 = UInt8((timestamp >> 8) & 0xFF)
		uuid.5 = UInt8(timestamp & 0xFF)
		
		uuid.6 = (uuid.6 & 0x0F) | 0x70
		uuid.8 = (uuid.8 & 0x3F) | 0x80
		
		return UUID(uuid: uuid)

	}
}
