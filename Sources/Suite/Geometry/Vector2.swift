//
//  Vector2.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/30/25.
//

import Foundation

public protocol Vector2: Hashable, StringInitializable, RawRepresentable {
	var x: CGFloat { get set }
	var y: CGFloat { get set }
	init(x: CGFloat, y: CGFloat)
	init(_ x: CGFloat, _ y: CGFloat)
}

public extension Vector2 {
	static func *(lhs: Self, rhs: any Vector2) -> Self {
		Self(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
	}
	
	static func *(lhs: Self, rhs: CGFloat) -> Self {
		Self(x: lhs.x * rhs, y: lhs.y * rhs)
	}
	
	static func /(lhs: Self, rhs: CGFloat) -> Self {
		Self(x: lhs.x / rhs, y: lhs.y / rhs)
	}
	
	static func +(lhs: Self, rhs: any Vector2) -> Self {
		Self(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
	}
	
	static func +=(lhs: inout Self, rhs: any Vector2) {
		lhs.x += rhs.x
		lhs.y += rhs.y
	}
	
	static func -(lhs: Self, rhs: Self) -> Self {
		Self(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
	}
	
	static func -=(lhs: inout Self, rhs: any Vector2) {
		lhs.x -= rhs.x
		lhs.y -= rhs.y
	}
	
	static func ≈≈(lhs: Self, rhs: any Vector2) -> Bool {
		lhs.isRoughlyEqual(to: rhs)
	}
	
	func scaled(by factor: CGFloat) -> Self { self * factor }
	
	func offset(x: Double = 0, y: Double = 0) -> Self {
		Self(x: self.x + x, y: self.y + y)
	}
}

extension CGPoint: Vector2 {}
extension CGSize: Vector2 {
	public var x: CGFloat {
		get { width }
		set { width = newValue }
	}
	public var y: CGFloat {
		get { height }
		set { height = newValue}
	}
	
	public init(x: CGFloat, y: CGFloat) {
		self = CGSize(width: x, height: y)
	}
}

public extension Vector2 {
	var largestDimension: CGFloat { max(x, y) }
	var smallestDimension: CGFloat { min(x, y) }
	var magnitude: CGFloat { sqrt(pow(x, 2) + pow(y, 2)) }
	
	init(_ x: CGFloat, _ y: CGFloat) {
		self = Self(x: x, y: y)
	}

	var stringValue: String {
		"(\(x), \(y))"
	}
	
	var description: String {
		"(\(x.string(decimalPlaces: 1, padded: false)), \(y.string(decimalPlaces: 1, padded: false)))"
	}
	
	var debugDescription: String { "(\(x.string(decimalPlaces: 1, padded: false)), \(y.string(decimalPlaces: 1, padded: false)))"}
	
	var rawValue: String { stringValue }

	init?(rawValue: String) {
		let components = rawValue.trimmingCharacters(in: .decimalDigits.inverted).components(separatedBy: ",")
		if components.count != 2 { return nil }
		
		guard let x = Double(components[0].trimmingCharacters(in: .whitespacesAndNewlines)), let y = Double(components[0].trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
		self = Self.init(x: x, y: y)
	}
	
	func rounded() -> Self {
		Self(x: roundcgf(value: x), y: roundcgf(value: y) )
	}
	
	func isRoughlyEqual(to other: any Vector2, tolerance: CGFloat? = nil) -> Bool {
		let eps = tolerance ?? CGFloat.ulpOfOne.squareRoot()

		return distance(to: other) < eps
	}
	
	func distance(to other: any Vector2) -> CGFloat {
		hypot(x - other.x, y - other.y)
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(x)
		hasher.combine(y)
	}
	
	var shortDescription: String {
		"(\(x.shortDescription), \(y.shortDescription))"
	}
}

