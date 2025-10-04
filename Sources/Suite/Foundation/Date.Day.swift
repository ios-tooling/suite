//
//  Date.Day.swift
//  
//
//  Created by Ben Gottlieb on 4/10/23.
//

import Foundation

public extension Date {
	struct Day: Codable, CustomStringConvertible, Equatable, Comparable, Hashable, Sendable {
		public var day: Int
		public var month: Foundation.Date.Month
		public var year: Int
		
		public var dayOfWeek: Date.DayOfWeek { date.dayOfWeek }
		
		public var description: String {
			if #available(iOS 15.0, macOS 12, watchOS 8, *) {
				return date.formatted(date: .numeric, time: .omitted)
			} else {
				return "\(year)-\(month.rawValue)-\(day)"
			}
		}
		
		public static func <(lhs: Self, rhs: Self) -> Bool {
			if lhs.year != rhs.year { return lhs.year < rhs.year }
			if lhs.month != rhs.month { return lhs.month < rhs.month }
			if lhs.day != rhs.day { return lhs.day < rhs.day }
			return false
		}
		
		public init?(mdy: String) {
			guard let components = mdy.dateComponents else { return nil }
			
			self.init(day: components[1], month: components[0], year: components[2])
		}
		
		public func previous(_ dayOfWeek: Date.DayOfWeek) -> Date.Day {
			var day = previousDay
			
			while day.dayOfWeek != dayOfWeek {
				day = day.previousDay
			}
			
			return day
		}
		
		public func next(_ dayOfWeek: Date.DayOfWeek) -> Date.Day {
			var day = nextDay
			
			while day.dayOfWeek != dayOfWeek {
				day = day.nextDay
			}
			
			return day
		}
		
		public func firstDayOfWeek(startingAt startDay: Date.DayOfWeek = .firstDayOfWeek) -> Date.Day {
			var day = self
			
			while day.dayOfWeek != startDay {
				day = day.previousDay
			}
			return day
		}
		
		public func isSameWeek(as day: Date.Day, startingAt startDay: Date.DayOfWeek = .firstDayOfWeek) -> Bool {
			day.firstDayOfWeek(startingAt: startDay) == firstDayOfWeek(startingAt: startDay)
		}
		
		public var previousDay: Date.Day { date.previousDay.day }
		public var nextDay: Date.Day { date.nextDay.day }

		public init?(dmy: String) {
			guard let components = dmy.dateComponents else { return nil }
			
			self.init(day: components[0], month: components[1], year: components[2])
		}
		
		public init?(ymd: String) {
			guard let components = ymd.dateComponents else { return nil }
			
			self.init(day: components[2], month: components[1], year: components[0])
		}
		
		public init(day: Int, month: Month, year: Int) {
			self.day = day
			self.month = month
			self.year = year
		}

		public init?(day: Int, month: Int, year: Int) {
			guard let actualMonth = Month(rawValue: month) else { return nil }
			self.day = day
			self.month = actualMonth
			self.year = year < 1000 ? year + 2000 : year
		}
		
		public init(_ date: Date) {
			self.day = date.dayOfMonth
			self.month = date.month
			self.year = date.year
		}
		
		public var date: Date {
			Date(calendar: .current, timeZone: .current, year: year, month: month.rawValue, day: day) ?? Date()
		}
		
		public var isInFuture: Bool {
			let now = Date.Day.now
			return self > now
		}
		
		public var isInPast: Bool {
			let now = Date.Day.now
			return self < now
		}
		
		public var isToday: Bool {
			let now = Date.Day.now
			return self == now
		}
		
		public var thisMinute: Date {
			Date(self, Date().time)
		}
		
		public var dmyString: String { dmyString() }
		public var ymdString: String { ymdString() }
		public var mdyString: String { mdyString() }

		public func dmyString(_ delim: String = "/") -> String { "\(day)\(delim)\(month.rawValue)\(delim)\(year)" }
		public func ymdString(_ delim: String = "/", useLeadingZeros: Bool = false) -> String {
			if useLeadingZeros {
				String(format: "\(year)\(delim)%02d\(delim)%02d", month.rawValue, day)
			} else {
				"\(year)\(delim)\(month.rawValue)\(delim)\(day)"
			}
		}
		public func mdyString(_ delim: String = "/") -> String { "\(month.rawValue)\(delim)\(day)\(delim)\(year)" }

		public func dmString(_ delim: String = "/") -> String { "\(day)\(delim)\(month.rawValue)" }
		public func mdString(_ delim: String = "/") -> String { "\(month.rawValue)\(delim)\(day)" }

		public var daysAgo: Int { Date().interval(ofComponent: .day, from: date) }
		public func daysFrom(_ day: Date.Day) -> Int { date.interval(ofComponent: .day, from: day.date) }

		public static var now: Date.Day { Date.Day(Date()) }
		public static var today: Date.Day { now }
	}
	
	var day: Day {
		Day(day: dayOfMonth, month: month, year: year)
	}
	
	init(_ date: Date.Day, _ time: Date.Time?) {
		self = Date(calendar: .current, timeZone: .current, year: date.year, month: date.month.rawValue, day: date.day, hour: time?.isNever == false ? time?.hour : nil, minute: time?.isNever == false ? time?.minute : nil) ?? Date()
	}
}

extension String {
	fileprivate var dateComponents: [Int]? {
		var comp = self.components(separatedBy: "/")
		if comp.count < 3 { comp = self.components(separatedBy: "-") }
		if comp.count < 3 { return nil }
		
		let ints = comp.compactMap { Int($0) }
		if ints.count < 3 { return nil }
		
		return ints.first(3)
	}
}
