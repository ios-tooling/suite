//
//  Date.Time.swift
//  
//
//  Created by Ben Gottlieb on 2/12/21.
//

import Foundation

public extension Date {
	struct Time: Codable, Comparable, Equatable, CustomStringConvertible {
		public let hour: Int
		public let minute: Int
		public let second: TimeInterval
		
		public static let midnight = Date.Time(hour: 0, minute: 0, second: 0)
		public static let lastSecond = Date.Time(hour: 23, minute: 59, second: 59 )

		public var timeInterval: TimeInterval {
			TimeInterval(hour * 3600) + TimeInterval(minute * 60) + second
		}
		
		public static func <(lhs: Time, rhs: Time) -> Bool {
			lhs.timeInterval < rhs.timeInterval
		}
		
		public static func ==(lhs: Time, rhs: Time) -> Bool {
			lhs.timeInterval == rhs.timeInterval
		}
		
		public init(hour: Int, minute: Int, second: TimeInterval = 0) {
			self.hour = min(hour, 23)
			self.minute = min(minute, 59)
			self.second = min(second, 59)
		}
		
		public var description: String {
			if second == 0 {
				return String(format: "%d:%02d", hour, minute)
			} else {
				return String(format: "%d:%02d:%02d", hour, minute, Int(second))
			}
		}
		
		public func timeInterval(since other: Date.Time) -> TimeInterval {
			let otherSeconds = other.timeInterval
			let mySeconds = self.timeInterval
			
			if otherSeconds < mySeconds {
				return mySeconds - otherSeconds
			}
			
			return Time.lastSecond.timeInterval(since: other) + self.timeInterval(since: .midnight)
		}
		
		public var nextHour: Time {
			Date.Time(hour: (hour + 1) % 24, minute: 0, second: 0)
		}
		
		public var topOfHour: Time {
			Date.Time(hour: hour, minute: 0, second: 0)
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
		
		public var date: Date {
			var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
			
			components.hour = hour
			components.minute = minute
			components.second = Int(second)
			
			
			return Calendar.current.date(from: components) ?? Date()
		}
		
		public var hourMinuteString: String {
			date.localTimeString(date: .none, time: .abbr)
		}
	}

	var time: Time {
		let components = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: self)
		return Time(hour: components.hour ?? 0, minute: components.minute ?? 0, second: TimeInterval(components.second ?? 0) + min(1, TimeInterval(components.nanosecond ?? 0) / 1_000_000_000))
	}
}