//
//  NumberFormatting.swift
//  
//
//  Created by Ben Gottlieb on 3/26/21.
//

import Foundation

#if canImport(UIKit)
	import UIKit
#elseif canImport(Cocoa)
	import Cocoa
#endif

public protocol DecimalFormattable {
	var doubleValue: Double { get }
}

extension CGFloat: DecimalFormattable {
	public var doubleValue: Double { Double(self) }
}

extension Double: DecimalFormattable {
	public var doubleValue: Double { self }
}

extension Float: DecimalFormattable {
	public var doubleValue: Double { Double(self) }
}

extension CGFloat {
	public func pretty(_ limit: Int? = 3, includeDecimal: Bool = true) -> String {
		Double(self).pretty(limit, includeDecimal: includeDecimal)
	}
}

extension Double {
	public func pretty(_ limit: Int? = 3, includeDecimal: Bool = true) -> String {
		var result = "\(self)"
		guard let decPos = result.position(of: ".") else { return result }
		
		if let limit, (result.count - decPos) > limit {
			result = result[0...(decPos + limit)]
			if !includeDecimal, result.hasSuffix(".") { result = String(result.dropLast()) }
			return result
		}
		while result.hasSuffix("0") { result = String(result.dropLast()) }
		if result.hasSuffix(".") {
			if includeDecimal { return result + "0" }
			return String(result.dropLast())
		}
		return result
	}
}

private let formatter: NumberFormatter = {
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	formatter.maximumFractionDigits = 2
	formatter.minimumFractionDigits = 2
	return formatter
}()

public extension DecimalFormattable {
	func string(decimalPlaces: Int = 2, padded: Bool = false) -> String {
		var result: String!
			
		if decimalPlaces <= 2 {
			result = formatter.string(from: NSNumber(value: doubleValue))
		}
		if result == nil {
			let fmt = NumberFormatter()
			fmt.numberStyle = .decimal
			fmt.maximumFractionDigits = decimalPlaces
			fmt.minimumFractionDigits = 2

			result = fmt.string(from: NSNumber(value: doubleValue))
		}
		
		while result.hasSuffix("0") || result.decimalPlaces > decimalPlaces {
			result = String(result.dropLast())
		}
		
		if padded {
			while result.decimalPlaces < decimalPlaces, result.count < 500 {
				result += "0"
			}
		} else {
			if result.hasSuffix(".") { result = String(result.dropLast()) }
		}
		
		return result
	}
}

public extension String {
	var decimalPlaces: Int {
		let radix = NumberFormatter.radix
		if !contains(radix) { return 0 }
		let components = self.components(separatedBy: radix)
		return components.last?.count ?? 0
	}
	
	var droppingDecimal: String {
		let components = self.components(separatedBy: NumberFormatter.radix)
		if components.count != 2 { return self }
		return components[0]
	}
}

extension NumberFormatter {
	static let radix: String = {
		if let radix = Locale.current.decimalSeparator { return radix }
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		guard let result = formatter.string(from: NSNumber(1.1)) else { return "." }
		if result.contains(".") { return "." }
		if result.contains(",") { return "," }
		if let last = result.trimmingCharacters(in: .alphanumerics).first {
			return String(last)
		}
		return "."
	}()
}
