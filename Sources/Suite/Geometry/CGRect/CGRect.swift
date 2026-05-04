//
//  CGRect.swift
//
//
//  Created by Ben Gottlieb on 12/2/19.
//

import Foundation
import CoreGraphics

#if os(iOS)
import UIKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

public func roundcgf(value: CGFloat) -> CGFloat { return CGFloat(floorf(Float(value))) }

extension CGRect: @retroactive Comparable {
	public static func <(lhs: CGRect, rhs: CGRect) -> Bool {
		lhs.area < rhs.area
	}
}

extension CGRect: @retroactive Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(origin)
		hasher.combine(size)
	}
}

extension CGRect: StringInitializable {
	public var rawValue: String { stringValue }

	public var stringValue: String {
		"(\(origin),\(size))"
	}

	public init?(rawValue: String) {
		let components = rawValue.trimmingCharacters(in: .decimalDigits.inverted).components(separatedBy: "),(")
		if components.count != 2 { return nil }

		guard let origin = CGPoint(rawValue: components[0].trimmingCharacters(in: .whitespacesAndNewlines)),
			let size = CGSize(rawValue: components[1].trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
		self.init(origin: origin, size: size)
	}
}

public extension CGRect {
	var area: CGFloat { width * height }

	static let unit = CGRect(x: 0, y: 0, width: 1, height: 1)

	#if os(iOS)
		typealias Placement = UIView.ContentMode
	#else
		enum Placement: Int, Sendable { case scaleToFill, scaleAspectFit, scaleAspectFill, none, center, top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight }
	#endif

	var xRange: Range<Double> { minX..<maxX }
	var yRange: Range<Double> { minY..<maxY }
}

public extension CGRect.Placement {
	var isLeft: Bool { self == .left || self == .topLeft || self == .bottomLeft }
	var isCenterH: Bool { self == .top || self == .center || self == .bottom }
	var isRight: Bool { self == .right || self == .topRight || self == .bottomRight }

	var isTop: Bool { self == .top || self == .topLeft || self == .topRight }
	var isCenterV: Bool { self == .left || self == .center || self == .right }
	var isBottom: Bool { self == .bottomLeft || self == .bottom || self == .bottomRight }

	var opposite: CGRect.Placement {
		switch self {
		case .scaleToFill: .scaleAspectFit
		case .scaleAspectFit: .scaleAspectFill
		case .scaleAspectFill: .scaleAspectFit
		case .center: .center
		case .top: .bottom
		case .bottom: .top
		case .left: .right
		case .right: .left
		case .topLeft: .bottomRight
		case .topRight: .bottomLeft
		case .bottomLeft: .topRight
		case .bottomRight: .topLeft
		default: self
		}
	}
}
