//
//  VersionString.swift
//  
//
//  Created by Ben Gottlieb on 9/24/21.
//

import Foundation

public struct VersionString: Comparable {
	let string: String
	
	var components: [Int] {
		string.components(separatedBy: ".").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
	}
	
	public static func ==(lhs: VersionString, rhs: VersionString) -> Bool {
		let lhComponents = lhs.components
		let rhComponents = rhs.components
		let minCount = min(lhComponents.count, rhComponents.count)
		
		let lPrefix = lhComponents.first(minCount)
		let rPrefix = rhComponents.first(minCount)
		
		if lPrefix != rPrefix { return false }
		if lhComponents.count > minCount {
			let suffix = lhComponents.suffix(from: lhComponents.count - minCount)
			return suffix.allSatisfy { $0 == 0 }
		}

		if rhComponents.count > minCount {
			let suffix = rhComponents.suffix(from: rhComponents.count - minCount)
			return suffix.allSatisfy { $0 == 0 }
		}
		
		return true
	}

	public static func <(lhs: VersionString, rhs: VersionString) -> Bool {
		let lComponents = lhs.components
		let rComponents = rhs.components
		
		for i in 0..<(max(lComponents.count, rComponents.count)) {
			let left = i < lComponents.count ? lComponents[i] : 0
			let right = i < rComponents.count ? rComponents[i] : 0
			
			if left < right { return true }
			if left > right { return false }
		}
		
		return false
	}

	public init(_ string: String) {
		self.string = string
	}
}
