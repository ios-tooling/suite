//
//  String+Subscript.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/10/19.
//

import Foundation

public extension String {
	subscript(i: Int) -> Character { self[self.index(i)] }
	subscript(range: Range<Int>) -> String { String(self[self.index(range.lowerBound)..<self.index(range.upperBound)]) }
	subscript(range: ClosedRange<Int>) -> String { String(self[self.index(range.lowerBound)...self.index(range.upperBound)]) }
	subscript(range: PartialRangeUpTo<Int>) -> String { String(self[self.startIndex..<self.index(range.upperBound)]) }
	subscript(range: PartialRangeFrom<Int>) -> String { String(self[self.index(range.lowerBound)..<self.endIndex]) }

	func range(_ range: Range<Int>) -> Range<String.Index> { self.index(range.lowerBound)..<self.index(range.upperBound) }
	func range(_ range: NSRange) -> Range<String.Index> { self.index(range.location)..<self.index(range.location + range.length) }
	func index(_ index: Int) -> String.Index { self.index(self.startIndex, offsetBy: min(index, self.count)) }
	var fullRange: Range<String.Index> { self.range(NSRange(location: 0, length: self.count)) }

	func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
		range(of: string, options: options)?.lowerBound
	}

	func position(of sub: String) -> Int? {
		if let index = index(of: sub) { return prefix(upTo: index).count }
		return nil
	}

	func extractSubstring(start: String, end: String) -> String? {
		guard let startIndex = self.range(of: start)?.upperBound,
			let endIndex = self.range(of: end, range: startIndex..<self.endIndex)?.lowerBound
		else {
			return nil
		}

		return String(self[startIndex..<endIndex])
	}
}
