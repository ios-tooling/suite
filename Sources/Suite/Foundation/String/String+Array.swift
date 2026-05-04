//
//  String+Array.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/10/19.
//

import Foundation

public extension Array where Element == String {
	var sequenceString: String {
		guard !self.isEmpty else { return "" }
		var result = self.first!
		if self.count == 1 { return result }

		for string in self.dropFirst().dropLast() {
			result += ", " + string
		}

		result += " " + NSLocalizedString("and", comment: "and") + " " + self.last!
		return result
	}
}

public extension Array where Element == String? {
	func concatenate(with separator: String, finalSeparator: String? = nil) -> String? {
		let collapsed = self.compactMap({ $0 })
		guard let first = collapsed.first else { return nil }

		if collapsed.count == 1 { return first }

		var result = first
		if collapsed.count > 2 {
			for i in collapsed.indices.dropFirst().dropLast() {
				result += separator + collapsed[i]
			}
		}
		result += (finalSeparator ?? separator) + collapsed.last!

		return result
	}
}
