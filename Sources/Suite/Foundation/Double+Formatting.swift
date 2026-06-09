//
//  Double+Formatting.swift
//  Suite
//

import Foundation

public extension Double {
	/// Compact K/M/B notation: 1_500 → "1.5K", 2_300_000 → "2.3M".
	var abbreviated: String {
		switch abs(self) {
		case ..<1_000:       return String(format: "%.2g", self)
		case ..<1_000_000:   return String(format: "%.3gK", self / 1_000)
		case ..<1_000_000_000: return String(format: "%.3gM", self / 1_000_000)
		default:             return String(format: "%.3gB", self / 1_000_000_000)
		}
	}

	/// The smallest "round" value ≥ `self` suitable as a chart Y-axis maximum.
	/// E.g. 1_234 → 2_000, 85 → 90, 0.7 → 1.
	var reasonableMaxValue: Double {
		if self <= 0 { return 1 }
		if self > 1_000_000 { return 1_000_000 * (self / 1_000_000).rounded(.up) }
		if self > 100_000  { return 100_000  * (self / 100_000).rounded(.up) }
		if self > 10_000   { return 10_000   * (self / 10_000).rounded(.up) }
		if self > 1_000    { return 1_000    * (self / 1_000).rounded(.up) }
		if self > 100      { return 100      * (self / 100).rounded(.up) }
		if self > 10       { return 10       * (self / 10).rounded(.up) }
		if self > 1        { return rounded(.up) }
		return 1
	}

	/// Evenly-spaced stop values from 0 to `reasonableMaxValue`, with `count` stops.
	func reasonableStops(count: Int) -> [Double] {
		guard count > 1 else { return [0] }
		let step = reasonableMaxValue / Double(count - 1)
		return (0..<count).map { Double($0) * step }
	}

	/// The smallest round maximum that can be evenly divided into `count - 1` intervals.
	func reasonableMaxValue(forSplittingInto count: Int) -> Double {
		guard count > 1 else { return reasonableMaxValue }
		return (reasonableMaxValue / Double(count - 1)).rounded(.up) * Double(count - 1)
	}
}
