//
//  Date+SA_Additions.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/10/19.
//  Copyright (c) 2019 Stand Alone, Inc. All rights reserved.
//

import Foundation

#if canImport(SwiftUI)
extension Date: @retroactive Identifiable {
	public var id: TimeInterval { return self.timeIntervalSinceReferenceDate }
}
#endif


public extension Date {
	enum StringLength: Int, Sendable { case normal, short, veryShort }

	func durationStringUntilNow(style: TimeInterval.DurationStyle = .seconds, showLeadingZero: Bool = true, roundUp: Bool = true) -> String {
		(-1 * timeIntervalSinceNow).durationString(style: style, showLeadingZero: showLeadingZero, roundUp: roundUp)
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
			if newValue == .pm { hour += 12 } else { hour -= 12 }
			self = byChanging(hour: hour)
		}
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

extension Set where Element == Calendar.Component {
	public static var all: Set<Calendar.Component> {
		[.era, .year, .month, .day, .hour, .minute, .second, .weekday, .weekdayOrdinal, .quarter, .weekOfMonth, .weekOfYear, .yearForWeekOfYear, .nanosecond, .calendar, .timeZone]
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
