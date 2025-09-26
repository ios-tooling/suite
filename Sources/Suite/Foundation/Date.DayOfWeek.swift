//
//  DayOfWeek.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/26/25.
//

import Foundation

#if canImport(SwiftUI)
extension Date.DayOfWeek: Identifiable {
	public var id: Int { return self.rawValue }
}
#endif

public extension Date {
	enum DayOfWeek: Int, CaseIterable, Codable, Comparable, CustomStringConvertible, Sendable { case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
		public var nextDay: DayOfWeek { increment(count: 1) }
		public var previousDay: DayOfWeek { increment(count: 6) }
		public func increment(count: Int) -> DayOfWeek { return DayOfWeek(rawValue: (self.rawValue + count - 1) % 7 + 1)! }
		public var abbreviation: String { return Calendar.current.veryShortWeekdaySymbols[self.rawValue - 1] }
		public var veryShortName: String {
			let str = Calendar.current.shortWeekdaySymbols[self.rawValue - 1]
			return str.count < 3 ? str : String(str.dropLast(str.count - 2))
		}
		public var shortName: String { return Calendar.current.shortWeekdaySymbols[self.rawValue - 1] }
		public var name: String { return Calendar.current.weekdaySymbols[self.rawValue - 1] }
		public var isWeekendDay: Bool { return self == .saturday || self == .sunday }
		public var isWeekDay: Bool { return !self.isWeekendDay }
		
		public static let firstDayOfWeek: DayOfWeek = { DayOfWeek(rawValue: Calendar.current.firstWeekday) ?? .monday }()
		public static let lastDayOfWeek: DayOfWeek = { firstDayOfWeek.previousDay }()
		public static let weekdays: [DayOfWeek] = {
			var days: [DayOfWeek] = []
			let first = Calendar.current.firstWeekday
			for i in 0..<7 {
				days.append(DayOfWeek(rawValue: (i + first + 7 - 1) % 7 + 1)!)
			}
			return days
		}()
		public static func <(lhs: DayOfWeek, rhs: DayOfWeek) -> Bool { return lhs.rawValue < rhs.rawValue }
		
		public var description: String { shortName }
		public func days(since day: DayOfWeek) -> Int {
			if day == self { return 0 }
			let weekdays = Self.weekdays
			let firstIndex = weekdays.firstIndex(of: day) ?? 0
			let lastIndex = weekdays.firstIndex(of: self) ?? 0
			
			return abs(lastIndex - firstIndex)
		}
	}
}
