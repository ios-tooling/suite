//
//  Date.Time+Formatting.swift
//  Suite
//
//  Created by Ben Gottlieb on 2/12/21.
//

import Foundation

public extension Date.Time {
	var description: String {
		if second == 0 {
			return String(format: "%d:%02d", visibleHour, minute)
		} else {
			return String(format: "%d:%02d:%02d", visibleHour, minute, Int(second))
		}
	}

	var stringValue: String { description }

	var visibleHour: Int {
		if Date.isIn24HourTimeMode { return hour }
		if hour == 0 || hour == 12 { return 12 }
		return hour % 12
	}

	var abbreviatedDescription: String {
		let suffix = Date.isIn24HourTimeMode ? "" : (hour < 12 ? "a" : "p")
		if minute == 0 { return "\(visibleHour)\(suffix)" }
		return String(format: "%d:%02d\(suffix)", visibleHour, minute)
	}

	var hourMinuteString: String {
		date.localTimeString(date: .none, time: .short)
	}

	var hourString: String {
		DateFormatter(format: "h").string(from: date)
	}

	var hourMinute24String: String {
		String(format: "%02d:%02d", hour, minute)
	}

	var meridian: Date.Meridian {
		if hour < 12 || hour == 24 { return .am }
		return .pm
	}
}
