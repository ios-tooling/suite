//
//  Date+Components.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/10/19.
//  Copyright (c) 2019 Stand Alone, Inc. All rights reserved.
//

import Foundation

public extension Date {
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
	var yearString: String { String(format: "%d", year) }

	var dayOfWeek: DayOfWeek { DayOfWeek(rawValue: self.components(which: .weekday).weekday!) ?? .sunday }
	var dayOfMonth: Int { Calendar.current.component(.day, from: self) }

	func dayOfWeekString(length: StringLength = .short) -> String {
		switch length {
		case .normal: return dayOfWeek.name
		case .short: return dayOfWeek.shortName
		case .veryShort: return dayOfWeek.abbreviation
		}
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
		return cal.date(from: components) ?? self
	}

	var lastDayInMonth: Date {
		let cal = Calendar.current
		var components = cal.dateComponents(in: TimeZone.current, from: self)
		components.day = self.numberOfDaysInMonth
		return cal.date(from: components) ?? self
	}

	var firstDayInWeek: Date {
		let weekDay = DayOfWeek.firstDayOfWeek
		let delta = dayOfWeek.days(since: weekDay)
		return self.byAdding(days: -delta)
	}

	var lastDayInWeek: Date {
		let weekDay = DayOfWeek.lastDayOfWeek
		let delta = weekDay.days(since: self.dayOfWeek)
		return self.byAdding(days: delta)
	}

	var dateOnly: Date { self.midnight }
	var timeOnly: Date { self }

	var noon: Date { self.hour(12) }
	func hour(_ hour: Int) -> Date { self.byChanging(nanosecond: 0, second: 0, minute: 0, hour: hour) }
	var midnight: Date { Calendar.current.startOfDay(for: self) }
	var midnightUTC: Date {
		let mid = midnight
		let offset = TimeZone.current.secondsFromGMT()
		return mid.addingTimeInterval(TimeInterval(offset))
	}
	var lastSecond: Date { self.byChanging(nanosecond: 0, second: 59, minute: 59, hour: 23) }

	var nearestSecond: Date {
		Date(timeIntervalSinceReferenceDate: floor(self.timeIntervalSinceReferenceDate))
	}

	var nearestHour: Date {
		var components = Calendar.current.dateComponents([.hour, .year, .month, .day], from: self)
		components.minute = 0
		components.second = 0
		return Calendar.current.date(from: components) ?? self
	}

	var nextNearestHour: Date {
		nearestHour.byAdding(hours: 1)
	}

	internal func components(which: Calendar.Component) -> DateComponents {
		Calendar.current.dateComponents([which], from: self)
	}
}
