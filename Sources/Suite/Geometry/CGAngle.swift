//
//  CGAngle.swift
//  Voronoi
//
//  Created by Ben Gottlieb on 5/1/23.
//

import Foundation
import SwiftUI

/// Three points (a, b, c). `angle` returns the interior angle at vertex `b` (i.e. between segments
/// `a→b` and `b→c`). Returns 0 for degenerate triangles (any two coincident points).
public struct CGAngle: Codable, Equatable, Hashable {
	public let a: CGPoint
	public let b: CGPoint
	public let c: CGPoint

	public init(a: CGPoint, b: CGPoint, c: CGPoint) {
		self.a = a
		self.b = b
		self.c = c
	}

	/// Interior angle at vertex `b`.
	public var angle: Angle {
		let ab = CGLine(start: a, end: b).length
		let bc = CGLine(start: b, end: c).length
		let ac = CGLine(start: a, end: c).length

		guard ab > 0, bc > 0 else { return .zero }

		let cosTheta = (pow(ab, 2) + pow(bc, 2) - pow(ac, 2)) / (2 * ab * bc)
		// Clamp to [-1, 1] in case floating-point error pushes us out of acos's domain.
		let clamped = max(-1, min(1, cosTheta))
		return .radians(acos(clamped))
	}
}
