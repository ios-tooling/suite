//
//  Date+Formatting.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/10/19.
//  Copyright (c) 2019 Stand Alone, Inc. All rights reserved.
//

import Foundation

public extension Date {
	var iso8601String: String {
		DateFormatter.iso8601.string(from: self)
	}

	init?(iso8601String: String) {
		if let date = DateFormatter.iso8601.date(from: iso8601String) {
			self = date
		} else {
			return nil
		}
	}

	var filename: String {
		DateFormatter.iso8601
			.string(from: self)
			.replacingOccurrences(of: ":", with: "-")
			.replacingOccurrences(of: "/", with: "-")
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

	var timeDescriptionWithMillisecond: String {
		let components = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: self)
		return String(format: "%d:%02d:%02d.%03d", components.hour ?? 0, components.minute ?? 0, components.second ?? 0, components.nanosecond! / 1_000_000)
	}

	func formatted(as format: String) -> String {
		DateFormatter(format: format).string(from: self)
	}

	@available(iOS 15.0, macOS 12, watchOS 9, tvOS 15, *)
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
}
