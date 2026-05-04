//
//  Date+Math.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/10/19.
//  Copyright (c) 2019 Stand Alone, Inc. All rights reserved.
//

import Foundation

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

	func byAdding(seconds: Int? = nil, minutes: Int? = nil, hours: Int? = nil, days: Int? = nil, months: Int? = nil, years: Int? = nil) -> Date {
		let calendar = Calendar.current
		let components = DateComponents(calendar: calendar, year: years, month: months, day: days, hour: hours, minute: minutes, second: seconds)
		return calendar.date(byAdding: components, to: self, wrappingComponents: false) ?? self
	}

	func byChanging(nanosecond: Int? = nil, second: Int? = nil, minute: Int? = nil, hour: Int? = nil, day: Int? = nil, month: Int? = nil, year: Int? = nil) -> Date {
		let units: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second, .nanosecond]
		let calendar = Calendar.current
		var components: DateComponents = calendar.dateComponents(units, from: self)

		if let nanosecond { components.nanosecond = nanosecond }
		if let second { components.second = second }
		if let minute { components.minute = minute }
		if let hour { components.hour = hour }
		if let day { components.day = day }
		if let month { components.month = month }
		if let year { components.year = year }

		return calendar.date(from: components) ?? self
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

	var secondsSinceMidnight: TimeInterval {
		abs(midnight.timeIntervalSince(self))
	}

	func bySettingSecondsSinceMidnight(_ seconds: TimeInterval) -> Date {
		midnight.addingTimeInterval(seconds)
	}

	func dateBySettingDate(date: Date?) -> Date {
		guard let date else { return self }
		let calendar = Calendar.current
		var components = calendar.dateComponents([.hour, .minute, .second, .year, .month, .day], from: self)
		let theirComponents = calendar.dateComponents([.year, .month, .day], from: date)

		components.year = theirComponents.year
		components.month = theirComponents.month
		components.day = theirComponents.day

		return calendar.date(from: components) ?? self
	}

	func dateBySetting(time: Date?) -> Date {
		guard let time else { return self }
		let calendar = Calendar.current
		var components = calendar.dateComponents([.hour, .minute, .second, .year, .month, .day], from: self)
		let theirComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

		components.hour = theirComponents.hour
		components.minute = theirComponents.minute
		components.second = theirComponents.second

		return calendar.date(from: components) ?? self
	}

	func dateBySetting(time: Date.Time?) -> Date {
		guard let time else { return self }
		let calendar = Calendar.current
		var components = calendar.dateComponents([.hour, .minute, .second, .year, .month, .day], from: self)

		components.hour = time.hour
		components.minute = time.minute
		components.second = Int(time.second)

		return calendar.date(from: components) ?? self
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

	func interval(ofComponent comp: Calendar.Component, from date: Date) -> Int {
		let currentCalendar = Calendar.current
		guard let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
		guard let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }
		return end - start
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
		self.next(dayOfWeek)
	}
}
