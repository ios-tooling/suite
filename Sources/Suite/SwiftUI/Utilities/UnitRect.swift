//
//  UnitRect.swift
//
//
//  Created by Ben Gottlieb on 10/29/23.
//

import SwiftUI

public func +(lhs: UnitPoint, rhs: UnitSize) -> UnitPoint {
	UnitPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
}

public func +=(lhs: inout UnitPoint, rhs: UnitSize) {
	lhs = lhs + rhs
}

public struct UnitSize: Hashable, Sendable, Equatable, CustomStringConvertible, Codable {
	public var width: CGFloat
	public var height: CGFloat
	
	public init(width: CGFloat, height: CGFloat) {
		self.width = width
		self.height = height
	}
	
	public init(_ width: CGFloat, _ height: CGFloat) {
		self.width = width
		self.height = height
	}
	
	public init(_ child: CGSize, in parent: CGSize) {
		self.init(width: child.width / parent.width, height: child.height / parent.height)
	}
	
	public static let full = UnitSize(width: 1.0, height: 1.0)
	public static let zero = UnitSize(width: 0, height: 0)
	
	public var description: String { "\(width.pretty()) x \(height.pretty())"}
	public func atLeast(_ size: UnitSize) -> UnitSize {
		.init(width: max(size.width, width), height: max(size.height, height))
	}
}

public struct UnitRect: Hashable, Sendable, Equatable, CustomStringConvertible, Codable {
	public var origin: UnitPoint
	public var size: UnitSize
	
	public var x: CGFloat { origin.x }
	public var y: CGFloat { origin.y }
	public var width: CGFloat { size.width }
	public var height: CGFloat { size.height }
	public var right: CGFloat { min(1.0, x + width) }
	public var bottom: CGFloat { min(1.0, y + height) }
	public var midX: CGFloat { size.width / 2 + origin.x }
	public var midY: CGFloat { size.height / 2 + origin.y }
	public var midPoint: UnitPoint { .init(x: midX, y: midY) }

	public init(origin: UnitPoint = .zero, size: UnitSize) {
		self.origin = origin
		self.size = size
	}
	
	public init(origin: UnitPoint = .zero, bottomRight: UnitPoint = .bottomLeading) {
		self.origin = origin
		self.size = .init(width: bottomRight.x - origin.x, height: bottomRight.y - origin.y)
	}
    
    public init(_ child: CGRect, in parent: CGRect) {
        if !parent.contains(child) { 
            self = .full
        } else {
            self = .init(
                origin: .init(x: (child.x - parent.x) / parent.width, y: (child.y - parent.y) / parent.height),
                size: .init(width: child.width / parent.width, height: child.height / parent.height)
            )
        }
    }
	
    public func contains(_ other: UnitRect) -> Bool {
        x <= other.x && y <= other.y && bottom >= other.bottom && right >= other.right
    }
    
    public func contains(_ point: UnitPoint) -> Bool {
        x <= point.x && y <= point.y && bottom >= point.y && right >= point.x
    }
    
	public func overlap(with other: UnitRect) -> UnitRect? {
		if right < other.x || x > other.right || bottom < other.y || y > other.bottom { return nil }
		
		let origin = UnitPoint(x: max(x, other.x), y: max(y, other.y))
		let bottomRight = UnitPoint(x: min(right, other.right), y: max(bottom, other.bottom))
		
		return UnitRect(origin: origin, bottomRight: bottomRight)
	}
    
    public func placed(in rect: CGRect) -> CGRect {
        CGRect(
            origin: .init(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y),
            size: .init(width: width * rect.width, height: height * rect.height)
        )
    }
	
	public static let full = UnitRect(origin: .zero, size: .full)
	public static let zero = UnitRect(origin: .zero, size: .zero)
	
	public var description: String { "(\(origin.x.pretty()), \(origin.y.pretty())), (\(size))"}
	public func union(with rect: UnitRect) -> UnitRect {
		.init(origin: .init(x: min(rect.x, x), y: min(rect.y, y)), bottomRight: .init(x: max(rect.right, right), y: max(rect.bottom, bottom)))
	}
}

fileprivate extension CGFloat {
	var short: String {
		String(format: "%.02f", self)
	}
}

public extension UnitPoint {
	init(from cgPoint: CGPoint, in frame: CGRect) {
		self.init(
			x: (cgPoint.x - frame.minX) / frame.width,
			y: (cgPoint.y - frame.minY) / frame.height
		)
	}
	
	func placed(in rect: CGRect) -> CGPoint {
		CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
	}
}

extension UnitPoint: @retroactive Codable {}

extension UnitPoint {
    enum CodingKeys: String, CodingKey, Sendable { case x, y }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let x = try container.decode(Double.self, forKey: .x)
        let y = try container.decode(Double.self, forKey: .y)
        self.init(x: x, y: y)
    }
}

