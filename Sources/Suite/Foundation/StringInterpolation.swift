//
//  StringInterpolation.swift
//  Suite
//
//  Created by Ben Gottlieb on 7/22/24.
//

import Foundation

public extension String.StringInterpolation {
	mutating func appendInterpolation<T: Encodable>(json value: T) {
		appendLiteral(value.prettyJSON ?? String(describing: value))
	}
}
