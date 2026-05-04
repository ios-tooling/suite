//
//  Date+Time.swift
//  Suite
//
//  Created by Ben Gottlieb on 2/12/21.
//

import Foundation

public extension Date {
	init?(time: Time?) {
		guard let time else { return nil }
		let now = Date()
		self.init(calendar: .current, timeZone: .current, year: now.year, month: now.month.rawValue, day: now.dayOfMonth, hour: time.hour, minute: time.minute, second: Int(time.second), nanosecond: 0)
	}

	func bySetting(time: Date.Time) -> Date {
		self.byChanging(nanosecond: nil, second: Int(time.second), minute: time.minute, hour: time.hour, day: nil, month: nil, year: nil)
	}

	func allHours(until end: Date) -> [Date] {
		var date = self

		if self.minute == 0 {
			date = self.nearestSecond
		} else {
			date = self.nearestHour.byAdding(hours: 1)
		}

		let count = Calendar.current.dateComponents([.hour], from: self, to: end).hour ?? 1
		return (0..<count).map { date.addingTimeInterval(TimeInterval($0) * .hour) }
	}

	func next(time: Date.Time) -> Date {
		let next = Date(time: time) ?? Date().previousDay
		if next < Date() {
			return next.nextDay
		}
		return next
	}

	var time: Time {
		get {
			let components = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: self)
			return Time(hour: components.hour ?? 0, minute: components.minute ?? 0, second: TimeInterval(components.second ?? 0) + min(1, TimeInterval(components.nanosecond ?? 0) / 1_000_000_000))
		}
		set {
			self = byChanging(second: Int(newValue.second), minute: newValue.minute, hour: newValue.hour)
		}
	}
}

extension Array where Element == Date.Time {
	public func average() -> Date.Time? {
		guard !isEmpty else { return nil }
		let sum = self.map { $0.timeInterval }.sum()
		return Date.Time(timeInterval: sum / TimeInterval(count))
	}
}
