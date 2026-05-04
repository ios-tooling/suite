//
//  Date+Comparison.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/10/19.
//  Copyright (c) 2019 Stand Alone, Inc. All rights reserved.
//

import Foundation

public func ≈≈(lhs: Date, rhs: Date) -> Bool {
	floor(lhs.timeIntervalSinceReferenceDate) == floor(rhs.timeIntervalSinceReferenceDate)
}

public func !≈(lhs: Date, rhs: Date) -> Bool {
	floor(lhs.timeIntervalSinceReferenceDate) != floor(rhs.timeIntervalSinceReferenceDate)
}

public extension Date {
	var isInFuture: Bool { timeIntervalSinceNow > 0 }
	var isInPast: Bool { timeIntervalSinceNow < 0 }

	var isToday: Bool { self.isSameDay(as: Date()) }
	var isTomorrow: Bool { self.isSameDay(as: Date().byAdding(days: 1)) }
	var isYesterday: Bool { self.isSameDay(as: Date().byAdding(days: -1)) }

	func isSameDay(as other: Date) -> Bool {
		Calendar.current.compare(self, to: other, toGranularity: .day) == .orderedSame
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
}

public extension Array where Element == Date {
	func contains(day: Date) -> Bool {
		self.firstIndex(ofDay: day) != nil
	}

	func firstIndex(ofDay day: Date) -> Int? {
		for i in self.indices where self[i].isSameDay(as: day) { return i }
		return nil
	}
}
