//
//  Optional.swift
//  
//
//  Created by Ben Gottlieb on 11/28/19.
//

import Foundation

public extension Optional where Wrapped: Comparable {
	static func <(lhs: Wrapped?, rhs: Wrapped?) -> Bool {
		switch (lhs, rhs) {
		case (nil, nil): return false
		case (nil, _?): return true
		case (_?, nil): return false
		case (let l?, let r?): return l < r
		}
	}
}

public extension Optional {
	enum UnwrappedOptionalError: Error, Sendable { case failedToUnwrap }
	func unwrap() throws -> Wrapped {
		switch self {
		case .none: throw UnwrappedOptionalError.failedToUnwrap
		case .some(let wrapped): return wrapped
		}
	}
}

public extension Optional where Wrapped: Collection {
	 var isEmpty: Bool {
		  switch self {
		  case .none: return true
		  case .some(let wrapped): return wrapped.isEmpty
		  }
	 }

	 var isNotEmpty: Bool {
		  switch self {
		  case .none: return false
		  case .some(let wrapped): return wrapped.isNotEmpty
		  }
	 }
}
