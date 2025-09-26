//
//  Month.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/26/25.
//

import Foundation

#if canImport(SwiftUI)
extension Date.Month: Identifiable {
	public var id: Int { return rawValue }
}
#endif

public extension Date {
	enum Month: Int, CaseIterable, Codable, Comparable, Sendable { case jan = 1, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec
		public var nextMonth: Month { return self.increment(by: 1) }
		public func increment(by: Int) -> Month { return Month(rawValue: (self.rawValue + by - 1) % 12 + 1)! }
		public var abbrev: String { return Calendar.current.veryShortMonthSymbols[self.rawValue] }
		public var shortName: String { return Calendar.current.shortMonthSymbols[self.rawValue - 1] }
		public var name: String { return Calendar.current.monthSymbols[self.rawValue - 1] }
		public var previous: Month? { .init(rawValue: rawValue - 1) }
		public var next: Month? { .init(rawValue: rawValue + 1) }
		public var standardDayCount: Int {
			switch self {
			case .jan, .mar, .may, .jul, .aug, .oct, .dec: 31
			case .apr, .jun, .sep, .nov: 30
			case .feb: 28
			}
		}
		
		public static func <(lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
	}
}
