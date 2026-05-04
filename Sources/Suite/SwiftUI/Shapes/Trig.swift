//
//  Trig.swift
//  Suite
//
//  Created by Ben Gottlieb on 3/8/25.
//

import SwiftUI

public extension Angle {
	enum Quadrant: String, Identifiable, Hashable, CaseIterable { case i, ii, iii, iv
		public var id: String { rawValue }
		public var isLeftHalf: Bool { self == .ii || self == .iii }
		public var isTopHalf: Bool { self == .i || self == .ii }
		public var title: String { rawValue.uppercased() }
	}
	
	var quadrant: Quadrant {
		if degrees <= 90 { return .i }
		if degrees <= 180 { return .iv }
		if degrees <= 270 { return .iii }
		return .ii
	}
	
	var adjustedForQuadrant: Angle {
		switch quadrant {
		case .i:
			let from90 = degrees
			return Angle.degrees(from90)

		case .ii:
			let from90 = degrees - 270
			return Angle.degrees(from90)

		case .iii:
			let from90 = degrees - 180
			return Angle.degrees(from90)

		case .iv:
			return Angle.degrees(degrees - 90)

		}
	}

}

public extension CGPoint {
	
	func quadrant(in size: CGSize) -> Angle.Quadrant {
		if x < size.width / 2 {			// either ii or iii
			y < size.height / 2 ? .ii : .iii
		} else {
			y < size.height / 2 ? .i : .iv
		}
	}
}

public extension CGRect {
	/// Point on a circle inscribed in this rect, at a clock-style angle (0° = 12 o'clock, increasing clockwise).
	/// `radius` is a 0...1 multiplier of `min(width, height) / 2`.
	func point(for angle: Angle, radius r: Double) -> CGPoint {
		let maxRadius = min(width, height) / 2
		let radius = r * maxRadius
		// Screen coordinates have y increasing downward, so cos is negated.
		return CGPoint(x: midX + radius * sin(angle.radians),
					   y: midY - radius * cos(angle.radians))
	}
}


