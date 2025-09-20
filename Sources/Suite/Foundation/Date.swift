//
//  Date+SA_Additions.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/10/19.
//  Copyright (c) 2019 Stand Alone, Inc. All rights reserved.
//

import Foundation

#if canImport(SwiftUI)
extension Date.Month: Identifiable {
	public var id: Int { return self.rawValue }
}

extension Date.DayOfWeek: Identifiable {
	public var id: Int { return self.rawValue }
}

extension Date: @retroactive Identifiable {
	public var id: TimeInterval { return self.timeIntervalSinceReferenceDate }
}
#endif


public extension Date {
	enum StringLength: Int, Sendable { case normal, short, veryShort }
	
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
	
	func durationStringUntilNow(style: TimeInterval.DurationStyle = .seconds, showLeadingZero: Bool = true, roundUp: Bool = true) -> String { (-1 * timeIntervalSinceNow).durationString(style: style, showLeadingZero: showLeadingZero, roundUp: roundUp) }
}

public extension Date {
	var iso8601String: String {
		DateFormatter.iso8601.string(from: self)
	}
	
	var nearestSecond: Date {
		return Date(timeIntervalSinceReferenceDate: floor(self.timeIntervalSinceReferenceDate))
	}
	
	var nearestHour: Date {
		var components = Calendar.current.dateComponents([.hour, .year, .month, .day], from: self)
		components.minute = 0
		components.second = 0
		
		return Calendar.current.date(from: components) ?? self
	}
	
	var nextNearestHour: Date {
		let hour = nearestHour
		return hour.byAdding(hours: 1)
	}
	
	var isInFuture: Bool {
		timeIntervalSinceNow > 0
	}
	
	var isInPast: Bool {
		timeIntervalSinceNow < 0
	}
	
	var filename: String {
		DateFormatter.iso8601
			.string(from: self)
			.replacingOccurrences(of: ":", with: "-")
			.replacingOccurrences(of: "/", with: "-")
	}
}

public func ≈≈(lhs: Date, rhs: Date) -> Bool {
	let lhSec = floor(lhs.timeIntervalSinceReferenceDate)
	let rhSec = floor(rhs.timeIntervalSinceReferenceDate)
	
	return lhSec == rhSec
}

public func !≈(lhs: Date, rhs: Date) -> Bool {
	let lhSec = floor(lhs.timeIntervalSinceReferenceDate)
	let rhSec = floor(rhs.timeIntervalSinceReferenceDate)
	
	return lhSec != rhSec
}

public extension Date {
	init?(calendar: Calendar, timeZone: TimeZone = .current, year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int = 0, nanosecond: Int = 0) {
		if year == nil, month == nil, day == nil, hour == nil, minute == nil, second == 0, nanosecond == 0 { return nil }
		let components = DateComponents(calendar: calendar, timeZone: timeZone, era: nil, year: year, month: month, day: day, hour: hour, minute: minute, second: second, nanosecond: nanosecond, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
		
		if let date = components.date {
			self = date
		} else {
			return nil
		}
	}
	func isSameWeek(as other: Date) -> Bool {
		let calendar = Calendar.current
		let myWeek = calendar.component(.weekOfYear, from: self)
		let otherWeek = calendar.component(.weekOfYear, from: other)
		return myWeek == otherWeek
	}
	
	func isSameMonth(as other: Date) -> Bool {
		let calendar = Calendar.current
		let myComponents = calendar.dateComponents([.month, .year], from: self)
		let otherComponents = calendar.dateComponents([.month, .year], from: other)
		return myComponents.month == otherComponents.month && myComponents.year == otherComponents.year
	}
	
	var isToday: Bool { self.isSameDay(as: Date()) }
	var isTomorrow: Bool { self.isSameDay(as: Date().byAdding(days: 1)) }
	var isYesterday: Bool { self.isSameDay(as: Date().byAdding(days: -1)) }
	
	func dateBySettingDate(date: Date?) -> Date {
		guard let date = date else { return self }
		let calendar = Calendar.current
		var components = calendar.dateComponents([.hour, .minute, .second, .year, .month, .day], from: self)
		let theirComponents = calendar.dateComponents([.year, .month, .day], from: date)
		
		components.year = theirComponents.year
		components.month = theirComponents.month
		components.day = theirComponents.day
		
		return calendar.date(from: components) ?? self
	}
	
	func dateBySetting(time: Date?) -> Date {
		guard let time = time else { return self }
		let calendar = Calendar.current
		var components = calendar.dateComponents([.hour, .minute, .second, .year, .month, .day], from: self)
		let theirComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
		
		components.hour = theirComponents.hour
		components.minute = theirComponents.minute
		components.second = theirComponents.second
		
		return calendar.date(from: components) ?? self
	}
	
	func dateBySetting(time: Date.Time?) -> Date {
		guard let time = time else { return self }
		let calendar = Calendar.current
		var components = calendar.dateComponents([.hour, .minute, .second, .year, .month, .day], from: self)
		
		components.hour = time.hour
		components.minute = time.minute
		components.second = Int(time.second)
		
		return calendar.date(from: components) ?? self
	}
	
	var dateOnly: Date { self.midnight }			/// returns midnight on the day in question
	var timeOnly: Date { self }						/// just returns the current date, since we're only interested in the time
	
	var year: Int { self.components(which: .year).year! }
	var month: Month { Month(rawValue: self.components(which: .month).month!) ?? .jan }
	var hour: Int { self.components(which: .hour).hour ?? 0 }
	var minute: Int { self.components(which: .minute).minute ?? 0 }
	var second: Int { self.components(which: .second).second ?? 0 }
	var millisecond: Int { (self.components(which: .nanosecond).nanosecond ?? 0) / 1_000_000 }
	var doubleSecond: TimeInterval {
		let interval = timeIntervalSinceReferenceDate
		
		return Double(second) + (interval - floor(interval))
	}
	var timeDescriptionWithMillisecond: String {
		let components = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: self)
		
		return String(format: "%d:%02d:%02d.%03d", components.hour ?? 0, components.minute ?? 0, components.second ?? 0, components.nanosecond! / 1_000_000)
		
	}
	
	var yearString: String { String(format: "%d", year) }
	
	var dayOfWeek: DayOfWeek { DayOfWeek(rawValue: self.components(which: .weekday).weekday!) ?? .sunday }
	var dayOfMonth: Int {
		let date = Calendar.current.component(.day, from: self)
		return date
	}
	func dayOfWeekString(length: StringLength = .short) -> String {
		let day = self.dayOfWeek
		
		switch length {
		case .normal: return day.name
		case .short: return day.shortName
		case .veryShort: return day.abbreviation
		}
	}
	
	func movedToTime(_ day: Date) -> Date {
		let cal = Calendar.current
		var myComponents = cal.dateComponents(in: TimeZone.current, from: day)
		let newComponents = cal.dateComponents(in: TimeZone.current, from: self)
		myComponents.month = newComponents.month
		myComponents.day = newComponents.day
		myComponents.year = newComponents.year
		return Calendar.current.date(from: myComponents) ?? self
	}
	
	var numberOfDaysInMonth: Int { Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 30 }
	
	static func numberOfDays(in month: Month, year: Int) -> Int {
		let components = DateComponents(year: year, month: month.rawValue)
		guard let date = Calendar.current.date(from: components) else { return 30 }
		return Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 30
	}
	
	var firstDayOfWeekInMonth: DayOfWeek { self.firstDayInMonth.dayOfWeek }
	
	var firstDayInMonth: Date {
		let cal = Calendar.current
		var components = cal.dateComponents(in: TimeZone.current, from: self)
		components.day = 1
		let date = cal.date(from: components)
		return date ?? self
	}
	
	var lastDayInMonth: Date {
		let cal = Calendar.current
		var components = cal.dateComponents(in: TimeZone.current, from: self)
		components.day = self.numberOfDaysInMonth
		let date = cal.date(from: components)
		return date ?? self
	}
	
	var firstDayInWeek: Date {
		let weekDay = DayOfWeek.firstDayOfWeek
		let delta = dayOfWeek.days(since: weekDay)
		return self.byAdding(days: delta)
	}
	
	var lastDayInWeek: Date {
		let weekDay = DayOfWeek.lastDayOfWeek
		let delta = weekDay.days(since: self.dayOfWeek)
		return self.byAdding(days: delta)
	}
	
	var hourMinuteString: String {
		let formatter = DateFormatter()
		formatter.dateStyle = .none
		formatter.timeStyle = .short
		return formatter.string(from: self)
	}
	
	var hourString: String {
		let isIn24HourTimeMode = Self.isIn24HourTimeMode
		var hour = isIn24HourTimeMode ? self.hour : self.hour % 12
		if !isIn24HourTimeMode, hour == 0 { hour = 12 }
		
		if isIn24HourTimeMode { return "\(hour)" }
		
		return "\(hour)" + (self.hour < 12 ? DateFormatter().amSymbol : DateFormatter().pmSymbol)
	}
	
	static var isIn24HourTimeMode: Bool {
		guard let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) else { return false }
		
		return format.range(of: "a") == nil
	}
	
	func byAdding(seconds: Int? = nil, minutes: Int? = nil, hours: Int? = nil, days: Int? = nil, months: Int? = nil, years: Int? = nil) -> Date {
		
		let calendar = Calendar.current
		let components = DateComponents(calendar: calendar, year: years, month: months, day: days, hour: hours, minute: minutes, second: seconds)
		
		return calendar.date(byAdding: components, to: self, wrappingComponents: false) ?? self
	}
	
	func byChanging(nanosecond: Int? = nil, second: Int? = nil, minute: Int? = nil, hour: Int? = nil, day: Int? = nil, month: Int? = nil, year: Int? = nil) -> Date {
		let units: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second, .nanosecond]
		let calendar = Calendar.current
		var components: DateComponents = calendar.dateComponents(units, from: self)
		
		if let nanosecond = nanosecond { components.nanosecond = nanosecond }
		if let second = second { components.second = second }
		if let minute = minute { components.minute = minute }
		if let hour = hour { components.hour = hour }
		if let day = day { components.day = day }
		if let month = month { components.month = month }
		if let year = year { components.year = year }
		
		return calendar.date(from: components) ?? self
	}
	
	var secondsSinceMidnight: TimeInterval {
		abs(midnight.timeIntervalSince(self))
	}
	
	func bySettingSecondsSinceMidnight(_ seconds: TimeInterval) -> Date {
		return self.midnight.addingTimeInterval(seconds)
	}
	
	var nextDay: Date {
		var components = DateComponents()
		components.day = 1
		
		return NSCalendar.current.date(byAdding: components, to: self, wrappingComponents: false) ?? self
	}
	
	var previousDay: Date {
		var components = DateComponents()
		components.day = -1
		
		return NSCalendar.current.date(byAdding: components, to: self, wrappingComponents: false) ?? self
	}
	
	var noon: Date { self.hour(12) }
	func hour(_ hour: Int) -> Date { self.byChanging(nanosecond: 0, second: 0, minute: 0, hour: hour) }
	var midnight: Date { Calendar.current.startOfDay(for: self) }
	var midnightUTC: Date {
		let mid = midnight
		let offset = TimeZone.current.secondsFromGMT()
		return mid.addingTimeInterval(TimeInterval(offset))
	}
	var lastSecond: Date { self.byChanging(nanosecond: 0, second: 59, minute: 59, hour: 23) }
	
	func allDays(until date: Date) -> [Date] {
		if date < self { return [] }
		var traveller = self
		var results: [Date] = []
		
		while traveller < date {
			results.append(traveller)
			traveller = traveller.nextDay
		}
		return results
	}
	//	func isAfter(date: Date) -> Bool { return self.earlierDate(date) != self && date != self }
	//	func isBefore(date: Date) -> Bool { return self.earlierDate(date) == self && date != self }
	
	func isSameDay(as other: Date) -> Bool {
		Calendar.current.compare(self, to: other, toGranularity: .day) == .orderedSame
	}
	
	var iso8691String: String {
		DateFormatter.iso8601.string(from: self)
	}
	
	init?(iso8691String: String) {
		if let date = DateFormatter.iso8601.date(from: iso8691String) {
			self = date
		} else {
			return nil
		}
	}
	
	private func components(which: Calendar.Component) -> DateComponents { return Calendar.current.dateComponents([which], from: self) }
	
	func interval(ofComponent comp: Calendar.Component, from date: Date) -> Int {
		 let currentCalendar = Calendar.current

		 guard let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
		 guard let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }

		 return end - start
	}
}

public extension Date {
	func formatted(as format: String) -> String {
		DateFormatter(format: format).string(from: self)
	}
	
	@available(iOS 15.0, macOS 12, *)
	func ageString(style: DateFormatter.Style = .short, showTimeAfter limit: TimeInterval? = nil) -> String {
		
		let age = timeIntervalSinceNow
		
		if let limit, abs(age) > limit {
			if isToday { return formatted(date: .omitted, time: .shortened) }
			
			return formatted(date: .abbreviated, time: .shortened)
		}
		
		return Date.ageString(age: timeIntervalSinceNow, style: style)
	}
	
	static func ageString(age: TimeInterval, style: DateFormatter.Style = .short) -> String {
		let seconds = abs(Int(age))
		let minutes = seconds / 60
		let hours = minutes / 60
		let days = hours / 24
		let weeks = days / 7
		let months = days / 30
		let years = months / 12
		
		if years > 0 {
			switch style {
			case .short: return "\(years)" + NSLocalizedString("y", comment: "short years")
			case .medium: return "\(years) " + NSLocalizedString("y", comment: "short years")
			case .long: return "\(years) " + NSLocalizedString("yr", comment: "medium years")
			case .full:
				if years == 1 { return NSLocalizedString("1 year", comment: "1 year") }
				return "\(years) " + NSLocalizedString("years", comment: "long years")
			default: return ""
			}
		}
		
		if months > 0 {
			switch style {
			case .short: return "\(months)" + NSLocalizedString("mo", comment: "short months")
			case .medium: return "\(months) " + NSLocalizedString("mo", comment: "short months")
			case .long: return "\(months) " + NSLocalizedString("mos", comment: "medium months")
			case .full:
				if months == 1 { return NSLocalizedString("1 month", comment: "1 month") }
				return "\(months) " + NSLocalizedString("months", comment: "long months")
			default: return ""
			}
		}
		
		if weeks > 0 {
			switch style {
			case .short: return "\(weeks)" + NSLocalizedString("w", comment: "short weeks")
			case .medium: return "\(weeks) " + NSLocalizedString("w", comment: "short weeks")
			case .long: return "\(weeks) " + NSLocalizedString("wk", comment: "medium weeks")
			case .full:
				if weeks == 1 { return NSLocalizedString("1 week", comment: "1 week") }
				return "\(weeks) " + NSLocalizedString("weeks", comment: "long weeks")
			default: return ""
			}
		}
		
		if days > 0 {
			switch style {
			case .short: return "\(days)" + NSLocalizedString("d", comment: "short days")
			case .medium: return "\(days) " + NSLocalizedString("d", comment: "short days")
			case .long: return "\(days) " + NSLocalizedString("days", comment: "medium days")
			case .full:
				if days == 1 { return NSLocalizedString("1 day", comment: "1 day") }
				return "\(days) " + NSLocalizedString("days", comment: "long days")
			default: return ""
			}
		}
		
		if hours > 0 {
			switch style {
			case .short: return "\(hours)" + NSLocalizedString("h", comment: "short hours")
			case .medium: return "\(hours) " + NSLocalizedString("h", comment: "short hours")
			case .long: return "\(hours) " + NSLocalizedString("hr", comment: "medium hours")
			case .full:
				if hours == 1 { return NSLocalizedString("1 hour", comment: "1 hour") }
				return "\(hours) " + NSLocalizedString("hours", comment: "long hours")
			default: return ""
			}
		}
		
		if minutes > 0 {
			switch style {
			case .short: return "\(minutes)" + NSLocalizedString("m", comment: "short minutes")
			case .medium: return "\(minutes) " + NSLocalizedString("m", comment: "short minutes")
			case .long: return "\(minutes) " + NSLocalizedString("min", comment: "medium minutes")
			case .full:
				if minutes == 1 { return NSLocalizedString("1 minute", comment: "1 minute") }
				return "\(minutes) " + NSLocalizedString("minutes", comment: "long minutes")
			default: return ""
			}
		}
		
		if seconds > 0 {
			switch style {
			case .short: return "\(seconds)" + NSLocalizedString("s", comment: "short seconds")
			case .medium: return "\(seconds) " + NSLocalizedString("s", comment: "short seconds")
			case .long: return "\(seconds) " + NSLocalizedString("sec", comment: "medium seconds")
			case .full:
				if seconds == 1 { return NSLocalizedString("1 second", comment: "1 second") }
				return "\(seconds) " + NSLocalizedString("seconds", comment: "long seconds")
			default: return ""
			}
		}
		
		return NSLocalizedString("now", comment: "now")
	}
	
	func previous(_ dayOfWeek: Date.DayOfWeek) -> Date {
		var date = self
		
		while date.dayOfWeek != dayOfWeek { date = date.previousDay }
		return date
	}
	
	func next(_ dayOfWeek: Date.DayOfWeek) -> Date {
		var date = self
		
		while date.dayOfWeek != dayOfWeek { date = date.nextDay }
		return date
	}
	
	func thisWeek(_ dayOfWeek: Date.DayOfWeek) -> Date {
		if dayOfWeek < self.dayOfWeek { return self.previous(dayOfWeek) }
		return self.next(dayOfWeek)
	}
	
	func upcoming(_ dayOfWeek: Date.DayOfWeek) -> Date {
		if dayOfWeek < self.dayOfWeek { return self.previous(dayOfWeek) }
		return self.next(dayOfWeek)
	}
}

public extension Int {
	var isLeapYear: Bool {
		let year = self
		
		if year % 4 != 0 { return false }
		if year % 400 == 0 { return true }
		return year % 100 != 0
	}
	
}

public extension Array where Element == Date {
	func contains(day: Date) -> Bool {
		return self.firstIndex(ofDay: day) != nil
	}
	
	func firstIndex(ofDay day: Date) -> Int? {
		for i in self.indices {
			if self[i].isSameDay(as: day) { return i }
		}
		return nil
	}
}

extension Set where Element == Calendar.Component {
	public static var all: Set<Calendar.Component> {
		[ .era, .year, .month, .day, .hour, .minute, .second, .weekday, .weekdayOrdinal, .quarter, .weekOfMonth, .weekOfYear, .yearForWeekOfYear, .nanosecond, .calendar, .timeZone ]
	}
}

public extension Date {
	enum Meridian: Sendable { case am, pm
		
		public static var shows: Bool {
			DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current)?.contains("a") == true
		}
	}
	
	var meridian: Meridian {
		get { hour < 12 ? .am : .pm }
		set {
			if meridian == newValue { return }
			var hour = self.hour
			
			if newValue == .pm {
				hour += 12
			} else {
				hour -= 12
			}
			
			self = byChanging(hour: hour)
		}
	}
}

extension Date: @retroactive RawRepresentable {
	public var rawValue: String {
		String(format: "%f", self.timeIntervalSinceReferenceDate)
	}
	
	public init?(rawValue: String) {
		self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
	}
}
