//
//  UnitPoint.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/30/25.
//

import Foundation

public extension UnitPoint {
	static var random: UnitPoint {
		UnitPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1))
	}
}
