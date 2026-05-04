//
//  CGFloat.swift
//  
//
//  Created by Ben Gottlieb on 5/1/23.
//

import Foundation

public extension CGFloat {
	/// Rounds to the nearest whole number and formats without decimals (e.g. 3.7 → "4", 0.001 → "0").
	/// Use `pretty` from `NumberFormatting.swift` if you want trailing-zero-stripped decimal output.
	var shortDescription: String {
		String(format: "%.0f", self)
	}
}

