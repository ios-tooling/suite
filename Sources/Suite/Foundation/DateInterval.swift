//
//  Date+Math.swift
//  
//
//  Created by Ben Gottlieb on 6/13/21.
//

import Foundation

@available(iOS 10.0, watchOS 5.0, *)
public extension Array where Element == DateInterval {
	func overlaps(with new: DateInterval) -> Bool {
		fullRange?.intersects(new) ?? false
	}
	
	var fullRange: DateInterval? {
		guard
			let start = self.sorted(by: { $0.start < $1.start }).first?.start,
			let end = self.sorted(by: { $0.end > $1.end }).last?.start else { return nil }
		return DateInterval(start: start, end: end)
	}
	
	mutating func add(_ new: DateInterval) {
		for interval in self {
			if interval.contains(new) { return }			// already contained within
		}

		for index in self.indices.reversed() {
			if new.contains(self[index]) { self.remove(at: index) }
		}

		let startIndex = firstIndex { $0.contains(new.start) }
		let endIndex = firstIndex { $0.contains(new.end) }
		
		if let firstIndex = startIndex, let lastIndex = endIndex {
			let first = self[firstIndex]
			let last = self[lastIndex]
			
			self.removeSubrange(firstIndex..<lastIndex)
			self.insert(DateInterval(start: first.start, end: last.end), at: firstIndex)
			return
		}
		
		if let firstIndex = startIndex {
			self[firstIndex].end = new.end
			
			return
		}

		if let lastIndex = endIndex {
			self[lastIndex].start = new.start
			return
		}
		
		self.append(new)
		self.sort() { $0.start < $1.start }
	}
}

@available(iOS 10.0, watchOS 5.0, *)
extension DateInterval: @retroactive RawRepresentable {
	static let separator = "/"
	public init?(rawValue: String) {
		let components = rawValue.components(separatedBy: Self.separator)
		if components.count != 2 { return nil }
		let formatter = ISO8601DateFormatter()
		
		guard let startDate = formatter.date(from: components[0]),
				let endDate = formatter.date(from: components[1]) else { return nil }
			
		self = .init(start: startDate, end: endDate)
	}
	
	public var rawValue: String {
		let formatter = ISO8601DateFormatter()
		
		return "\(formatter.string(from: start))\(Self.separator)\(formatter.string(from: end))"
	}
	

}

@available(iOS 10.0, watchOS 5.0, *)
public extension DateInterval {
	func contains(_ interval: DateInterval) -> Bool {
		start <= interval.start && end >= interval.end
	}
	
	static func +(lhs: DateInterval, rhs: DateInterval) -> DateInterval {
		DateInterval(start: min(lhs.start, rhs.start), end: max(lhs.end, rhs.end))
	}
	
	init(_ range: Range<Date>) {
		self.init(start: range.lowerBound, end: range.upperBound)
	}
	
	func randomDate() -> Date {
		start.addingTimeInterval(Double.random(in: 0...duration))
	}
}
