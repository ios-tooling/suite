//
//  File.swift
//  Suite
//
//  Created by Ben Gottlieb on 7/22/24.
//

import SwiftUI

public extension String.StringInterpolation {
	mutating func appendInterpolation<T: Encodable>(json value: T) {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		
		if let result = value.prettyJSON {
			appendLiteral(result)
		}
	}}
