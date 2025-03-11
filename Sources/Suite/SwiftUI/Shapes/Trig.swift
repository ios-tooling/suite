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
	func point(for angle: Angle, radius r: Double) -> CGPoint {
		let adjustedAngle = angle.adjustedForQuadrant
		let maxRadius = min(width, height) / 2
		
		let x = r * maxRadius * sin(adjustedAngle.radians)
		let y = r * maxRadius * cos(adjustedAngle.radians)
		
		switch angle.quadrant {
		case .i: return .init(x: midX + x, y: midY - y)
		case .ii: return .init(x: midX - y, y: midY - x)
		case .iii: return .init(x: midX - x, y: midY + y)
		case .iv: return .init(x: midX + y, y: midY + x)
		}
	}
}


