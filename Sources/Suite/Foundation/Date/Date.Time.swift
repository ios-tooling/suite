//
//  Date.Time.swift
//
//
//  Created by Ben Gottlieb on 2/12/21.
//

import Foundation

#if canImport(SwiftUI)
extension Date.Time: Identifiable {
	public var id: TimeInterval { timeInterval }
}
#endif

public extension Date {
	struct Time: Codable, Comparable, Equatable, CustomStringConvertible, Hashable, Sendable {
		public var hour: Int
		public var minute: Int
		public var second: TimeInterval

		public static let midnight = Date.Time(hour: 0, minute: 0, second: 0)
		public static let lastSecond = Date.Time(hour: 23, minute: 59, second: 59)
		public static let never = Date.Time(hour: -1, minute: -1)

		public var timeInterval: TimeInterval {
			TimeInterval(hour * 3600) + TimeInterval(minute * 60) + second
		}

		public var isNever: Bool { hour == -1 || minute == -1 }

		public static func <(lhs: Time, rhs: Time) -> Bool {
			lhs.timeInterval < rhs.timeInterval
		}

		public static func ==(lhs: Time, rhs: Time) -> Bool {
			lhs.timeInterval == rhs.timeInterval
		}

		public init(hour: Int, minute: Int, second: TimeInterval = 0) {
			self.hour = hour % 24
			self.minute = min(minute, 59)
			self.second = min(second, 59)
		}

		public init?(string: String) {
			let chunks = string.components(separatedBy: .whitespaces)
			guard let hourMinuteChunk = chunks.first else { return nil }
			let components = hourMinuteChunk.components(separatedBy: ":")
			guard components.count >= 2, let hour = Int(components[0]), let minute = Int(components[1]) else { return nil }

			if chunks.count > 1, chunks[1].lowercased() == "pm", hour < 12, hour != 0 {
				self.hour = hour + 12
			} else {
				self.hour = hour
			}

			self.minute = minute
			if components.count > 2, let sec = TimeInterval(components[2]) {
				self.second = sec
			} else {
				self.second = 0
			}
		}

		public init(timeInterval: TimeInterval) {
			hour = Int(timeInterval / 3600) % 24
			minute = Int(timeInterval / 60) % 60
			second = TimeInterval(Int(timeInterval) % 60)
		}

		public static var now: Date.Time {
			.init(timeInterval: Date().timeIntervalSince(Date().midnight))
		}

		public func allHours(until end: Date.Time) -> [Date.Time] {
			var times: [Date.Time] = []

			if minute == 0 {
				times.append(Date.Time(hour: hour, minute: 0))
			}

			let end = end.hour <= hour ? end.hour + 12 : end.hour
			for hour in (hour + 1)...(end) {
				times.append(Date.Time(hour: hour % 24, minute: 0))
			}

			return times
		}

		public func isSameMinute(as time: Date.Time) -> Bool {
			hour == time.hour && minute == time.minute
		}

		public func roundedToNearest(minute: Int) -> Date.Time {
			if (minute + self.minute) >= 60 { return Date.Time(hour: (hour + 1) % 24, minute: 0) }
			return Date.Time(hour: hour, minute: minute * Int(round(Double(self.minute) / Double(minute))))
		}

		public var date: Date {
			get {
				var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
				components.hour = hour
				components.minute = minute
				components.second = Int(second)
				return Calendar.current.date(from: components) ?? Date()
			}
			set {
				let components = Calendar.current.dateComponents([.hour, .minute, .second], from: newValue)
				hour = components.hour ?? 0
				minute = components.minute ?? 0
				second = Double(components.second ?? 0)
			}
		}

		public struct Frame {
			public let start: Time
			public let end: Time

			public init(_ start: Time, _ end: Time) {
				self.start = start
				self.end = end
			}

			public var duration: TimeInterval { end.timeInterval(since: start) }
		}
	}
}

public extension Date.Time {
	func byAdding(timeInterval: TimeInterval) -> Date.Time {
		let sign = timeInterval >= 0 ? 1.0 : -1.0
		let hours = timeInterval > .hour ? floor(timeInterval / .hour) : 0
		let minutes = sign * (abs(timeInterval) - floor(hours) * .hour) / .minute
		let seconds = TimeInterval(Int(timeInterval) % 60)

		return byAdding(hours: Int(hours), minutes: Int(minutes), seconds: seconds)
	}

	func byAdding(hours: Int = 0, minutes: Int = 0, seconds: TimeInterval = 0) -> Date.Time {
		var second = self.second + TimeInterval(Int(seconds) % 60)
		var minute = self.minute + minutes + Int(seconds / 60) % 60
		var hour = (self.hour + hours + 24 + Int(seconds / 3600)) % 24

		if second < 0 {
			minute -= 1
			second += 60
		} else if second > 60 {
			minute += 1
			second -= 60
		}

		if minute < 0 {
			hour -= 1
			minute += 60
		} else if minute >= 60 {
			hour += 1
			minute -= 60
		}
		return Date.Time(hour: hour, minute: minute, second: second)
	}

	static func -(lhs: Date.Time, rhs: Date.Time) -> Date.Time {
		lhs.byAdding(hours: -rhs.hour, minutes: -rhs.minute, seconds: -rhs.second)
	}

	var timeIntervalSinceNow: TimeInterval {
		timeInterval(since: Date().time)
	}

	func timeInterval(since other: Date.Time) -> TimeInterval {
		if self == other { return 0 }
		let otherSeconds = other.timeInterval
		let mySeconds = self.timeInterval

		if otherSeconds <= mySeconds {
			return mySeconds - otherSeconds
		}

		return Date.Time.lastSecond.timeInterval(since: other) + self.timeInterval(since: .midnight)
	}

	var nextHour: Date.Time {
		Date.Time(hour: (hour + 1) % 24, minute: 0, second: 0)
	}

	var topOfHour: Date.Time {
		Date.Time(hour: hour, minute: 0, second: 0)
	}
}
