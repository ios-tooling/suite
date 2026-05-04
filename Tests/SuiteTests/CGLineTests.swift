//
//  CGLineTests.swift
//  Suite
//
//  Created by Claude Code
//

import Testing
import Foundation
import SwiftUI
@testable import Suite

@Suite("CGLine Tests")
struct CGLineTests {

	// MARK: - Hashable contract

	@Test("Hashable contract: equal lines must have equal hashes (forward)")
	func hashableContractForward() {
		let a = CGLine(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 10, y: 0))
		let b = CGLine(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 10, y: 0))

		#expect(a == b)
		#expect(a.hashValue == b.hashValue)
	}

	@Test("Hashable contract: reversed lines are equal and must have equal hashes")
	func hashableContractReversed() {
		let forward = CGLine(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 10, y: 0))
		let reversed = CGLine(start: CGPoint(x: 10, y: 0), end: CGPoint(x: 0, y: 0))

		// == is order-independent, so the hash must be too.
		#expect(forward == reversed)
		#expect(forward.hashValue == reversed.hashValue)
	}

	@Test("Set membership respects reversed equality")
	func setMembership() {
		let forward = CGLine(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 10, y: 0))
		let reversed = CGLine(start: CGPoint(x: 10, y: 0), end: CGPoint(x: 0, y: 0))

		var set: Set<CGLine> = []
		set.insert(forward)
		// If hashing is consistent with ==, inserting reversed should be a no-op.
		set.insert(reversed)
		#expect(set.count == 1)
	}

	// MARK: - Angle construction

	@Test("Line at 0 degrees ends to the right")
	func lineAtZeroDegrees() {
		let line = CGLine(start: .zero, length: 10, angle: .degrees(0))
		#expect(line.end ≈≈ CGPoint(x: 10, y: 0))
	}

	@Test("Line at 90 degrees ends below (positive y in screen coords)")
	func lineAt90Degrees() {
		let line = CGLine(start: .zero, length: 10, angle: .degrees(90))
		#expect(line.end ≈≈ CGPoint(x: 0, y: 10))
	}

	@Test("Line at 180 degrees ends to the left")
	func lineAt180Degrees() {
		let line = CGLine(start: .zero, length: 10, angle: .degrees(180))
		#expect(line.end ≈≈ CGPoint(x: -10, y: 0))
	}

	@Test("Line at 270 degrees ends above")
	func lineAt270Degrees() {
		let line = CGLine(start: .zero, length: 10, angle: .degrees(270))
		#expect(line.end ≈≈ CGPoint(x: 0, y: -10))
	}

	// MARK: - Length / slope

	@Test("Horizontal length")
	func lengthHorizontal() {
		let line = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0))
		#expect(line.length == 10)
	}

	@Test("Diagonal length (3-4-5 triangle)")
	func lengthDiagonal() {
		let line = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 3, y: 4))
		#expect(line.length == 5)
	}

	@Test("Slope of horizontal line is zero")
	func slopeHorizontal() {
		let line = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0))
		#expect(line.slope == 0)
	}

	@Test("Slope of 45-degree line is 1")
	func slope45() {
		let line = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 10))
		#expect(line.slope == 1)
	}

	@Test("Slope of vertical line is infinite")
	func slopeVertical() {
		let line = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 10))
		#expect(line.slope.isInfinite)
	}

	// MARK: - Axis detection

	@Test("Horizontal line is detected")
	func axisHorizontal() {
		let line = CGLine(CGPoint(x: 0, y: 5), CGPoint(x: 10, y: 5))
		#expect(line.isHorizontal)
		#expect(!line.isVertical)
	}

	@Test("Vertical line is detected")
	func axisVertical() {
		let line = CGLine(CGPoint(x: 5, y: 0), CGPoint(x: 5, y: 10))
		#expect(line.isVertical)
		#expect(!line.isHorizontal)
	}

	// MARK: - Midpoint

	@Test("Midpoint getter returns centre of segment")
	func midpointGetter() {
		let line = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0))
		#expect(line.midpoint == CGPoint(x: 5, y: 0))
	}

	@Test("Midpoint setter shifts both endpoints by the same delta (symmetric)")
	func midpointSetterSymmetric() {
		var line = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0))
		// Old midpoint: (5, 0). New midpoint: (5, 5). Delta: (0, 5).
		line.midpoint = CGPoint(x: 5, y: 5)

		#expect(line.start ≈≈ CGPoint(x: 0, y: 5))
		#expect(line.end ≈≈ CGPoint(x: 10, y: 5))
		#expect(line.midpoint ≈≈ CGPoint(x: 5, y: 5))
	}

	@Test("Midpoint setter shifts both endpoints by the same delta (asymmetric)")
	func midpointSetterAsymmetric() {
		var line = CGLine(CGPoint(x: 2, y: 4), CGPoint(x: 8, y: 10))
		// Old midpoint: (5, 7). New midpoint: (10, 10). Delta: (5, 3).
		line.midpoint = CGPoint(x: 10, y: 10)

		#expect(line.start ≈≈ CGPoint(x: 7, y: 7))
		#expect(line.end ≈≈ CGPoint(x: 13, y: 13))
		#expect(line.midpoint ≈≈ CGPoint(x: 10, y: 10))
	}

	@Test("Midpoint setter preserves length")
	func midpointSetterPreservesLength() {
		var line = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 6, y: 8))
		let originalLength = line.length

		line.midpoint = CGPoint(x: 100, y: 100)

		#expect(abs(line.length - originalLength) < 0.0001)
	}

	// MARK: - Intersection

	@Test("Crossing perpendicular lines intersect at expected point")
	func crossingLines() {
		let horizontal = CGLine(CGPoint(x: 0, y: 5), CGPoint(x: 10, y: 5))
		let vertical = CGLine(CGPoint(x: 5, y: 0), CGPoint(x: 5, y: 10))

		let intersection = horizontal.intersection(with: vertical)
		#expect(intersection != nil)
		if let intersection {
			#expect(intersection ≈≈ CGPoint(x: 5, y: 5))
		}
	}

	@Test("Parallel lines do not intersect")
	func parallelLinesNoIntersection() {
		let a = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0))
		let b = CGLine(CGPoint(x: 0, y: 5), CGPoint(x: 10, y: 5))

		#expect(a.intersection(with: b) == nil)
	}

	// MARK: - isParallel

	@Test("Same-direction parallel lines")
	func parallelSameDirection() {
		let a = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0))
		let b = CGLine(CGPoint(x: 0, y: 5), CGPoint(x: 10, y: 5))
		#expect(a.isParallel(to: b))
	}

	@Test("Anti-parallel lines (opposite direction) are parallel")
	func parallelAntiParallel() {
		let a = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0))
		let b = CGLine(CGPoint(x: 10, y: 5), CGPoint(x: 0, y: 5))
		#expect(a.isParallel(to: b))
	}

	@Test("Non-parallel lines")
	func notParallel() {
		let a = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0))
		let b = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 10))
		#expect(!a.isParallel(to: b))
	}

	// MARK: - rawValue round-trip

	@Test("Round-trip rawValue with positive coordinates")
	func roundTripPositive() {
		let original = CGLine(CGPoint(x: 1, y: 2), CGPoint(x: 3, y: 4))
		let raw = original.rawValue
		let parsed = CGLine(rawValue: raw)

		#expect(parsed != nil)
		if let parsed {
			#expect(parsed.start ≈≈ original.start)
			#expect(parsed.end ≈≈ original.end)
		}
	}

	@Test("Round-trip rawValue with negative coordinates")
	func roundTripNegative() {
		let original = CGLine(CGPoint(x: -1, y: -2), CGPoint(x: -3, y: -4))
		let raw = original.rawValue
		let parsed = CGLine(rawValue: raw)

		#expect(parsed != nil)
		if let parsed {
			#expect(parsed.start ≈≈ original.start)
			#expect(parsed.end ≈≈ original.end)
		}
	}

	@Test("Round-trip rawValue with fractional coordinates")
	func roundTripFractional() {
		let original = CGLine(CGPoint(x: 1.5, y: 2.25), CGPoint(x: -3.75, y: 4.125))
		let raw = original.rawValue
		let parsed = CGLine(rawValue: raw)

		#expect(parsed != nil)
		if let parsed {
			#expect(parsed.start ≈≈ original.start)
			#expect(parsed.end ≈≈ original.end)
		}
	}

	// MARK: - Flip

	@Test("Flip swaps start and end")
	func flip() {
		var line = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 5))
		line.flip()
		#expect(line.start == CGPoint(x: 10, y: 5))
		#expect(line.end == CGPoint(x: 0, y: 0))
	}

	@Test("Flipped returns reversed copy without mutation")
	func flipped() {
		let line = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 5))
		let flipped = line.flipped

		#expect(flipped.start == line.end)
		#expect(flipped.end == line.start)
		#expect(line.start == CGPoint(x: 0, y: 0))
	}

	// MARK: - Highest / lowest

	@Test("Lowest point has the larger y in screen coordinates")
	func lowestPoint() {
		let line = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 5))
		#expect(line.lowestPoint == CGPoint(x: 10, y: 5))
	}

	@Test("Highest point has the smaller y in screen coordinates")
	func highestPoint() {
		let line = CGLine(CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 5))
		#expect(line.highestPoint == CGPoint(x: 0, y: 0))
	}
}

@Suite("Vector2 rawValue Tests")
struct Vector2RawValueTests {

	@Test("CGPoint round-trip with positive coordinates")
	func cgPointRoundTripPositive() {
		let original = CGPoint(x: 1.5, y: 2.5)
		let parsed = CGPoint(rawValue: original.rawValue)
		#expect(parsed != nil)
		if let parsed { #expect(parsed ≈≈ original) }
	}

	@Test("CGPoint round-trip with negative coordinates")
	func cgPointRoundTripNegative() {
		let original = CGPoint(x: -1.5, y: -2.5)
		let parsed = CGPoint(rawValue: original.rawValue)
		#expect(parsed != nil)
		if let parsed { #expect(parsed ≈≈ original) }
	}

	@Test("CGPoint round-trip with mixed signs")
	func cgPointRoundTripMixed() {
		let original = CGPoint(x: -3.14, y: 2.71)
		let parsed = CGPoint(rawValue: original.rawValue)
		#expect(parsed != nil)
		if let parsed { #expect(parsed ≈≈ original) }
	}
}
