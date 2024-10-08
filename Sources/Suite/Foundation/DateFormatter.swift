//
//  DateFormatter.swift
//  
//
//  Created by Ben Gottlieb on 12/2/19.
//

import Foundation

extension Formatter: @unchecked @retroactive Sendable { }

public extension DateFormatter {
	static let iso8601: ISO8601DateFormatter = {
		ISO8601DateFormatter()
	}()

	static let fractionalISO8601: ISO8601DateFormatter = {
		let formatter = ISO8601DateFormatter()
		
		formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
		
		return formatter
	}()

	convenience init(format: String) {
		self.init()
		self.dateFormat = format
		self.locale = Locale(identifier: "en_US_POSIX")
	}
	
	static let defaultJSONFormatter = DateFormatter.iso8601
}
