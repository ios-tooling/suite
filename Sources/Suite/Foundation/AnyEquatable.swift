//
//  AnyEquatable.swift
//  Suite
//
//  Created by Ben Gottlieb on 3/1/25.
//

import Foundation

public func isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
	// if they're both arrays, check each item by index
	if let a1 = lhs as? [Any], let a2 = rhs as? [Any] {
		guard a1.count == a2.count else { return false }
		for (i1, i2) in zip(a1, a2) {
			if !isEqual(i1, i2) { return false }
		}
		return true
	}
	
	//if they're both dictionaries, check each item by key
	if let d1 = lhs as? [AnyHashable: Any], let d2 = rhs as? [AnyHashable: Any] {
		guard d1.count == d2.count else { return false }
		for key in d1.keys {
			guard let i1 = d1[key], let i2 = d2[key] else { return false }
			if !isEqual(i1, i2) { return false }
		}
		return true
	}
	
	if let eq = lhs as? any Equatable {
		return checkEquality(eq, rhs)
	}
	return false
}

func checkEquality<T: Equatable>(_ lhs: T, _ rhs: Any) -> Bool {
	if let r = rhs as? T { return r == lhs }
	return false
}
