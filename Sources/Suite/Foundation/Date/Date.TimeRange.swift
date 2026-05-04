//
//  Date.TimeRange.swift
//  Suite
//
//  Created by Ben Gottlieb on 2/12/21.
//

import Foundation

public extension Date {
	struct TimeRange: Equatable, CustomStringConvertible, Codable, Hashable, Sendable {
		public var start: Date.Time
		public var end: Date.Time

		public init(_ start: Date.Time, _ end: Date.Time) {
			self.start = start
			self.end = end
		}

		public init(start: Date.Time, duration: TimeInterval) {
			self.start = start
			self.end = start.byAdding(timeInterval: duration)
		}

		public init(startMinute minutes: Int, duration: TimeInterval) {
			let startHour = minutes / 60
			let startMinute = minutes % 60

			let endHour = (minutes + Int(duration / 60)) / 60
			let endMinute = (minutes + Int(duration / 60)) % 60

			self.init(.init(hour: startHour, minute: startMinute), .init(hour: endHour, minute: endMinute))
		}

		public func dateInterval(on date: Date) -> DateInterval {
			let start = date.bySetting(time: start)
			return DateInterval(start: start, duration: duration)
		}

		public func shortened(by interval: TimeInterval) -> TimeRange? {
			if interval > self.duration { return nil }
			return TimeRange(start: start, duration: duration - interval)
		}

		public var duration: TimeInterval {
			if start <= end {
				return end.timeInterval - start.timeInterval
			}
			return (Date.Time.lastSecond.timeInterval - start.timeInterval) + (end.timeInterval)
		}

		public static func ==(lhs: Self, rhs: Self) -> Bool {
			lhs.start == rhs.start && lhs.end == rhs.end
		}

		public func intersection(with time: TimeRange) -> TimeRange? {
			if end.timeInterval < time.start.timeInterval || start.timeInterval > time.end.timeInterval { return nil }

			let newStart = max(start.timeInterval, time.start.timeInterval)
			let newEnd = min(end.timeInterval, time.end.timeInterval)

			return TimeRange(.init(timeInterval: newStart), .init(timeInterval: newEnd))
		}

		public var description: String {
			if start == end { return "\(start)" }
			return "\(start) - \(end)"
		}

		public var abbreviatedDescription: String {
			if start == end { return "\(start.abbreviatedDescription)" }
			return "\(start.abbreviatedDescription) - \(end.abbreviatedDescription)"
		}
	}
}
