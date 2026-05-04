//
//  CGRect+Slicing.swift
//
//
//  Created by Ben Gottlieb on 12/2/19.
//

import Foundation
import CoreGraphics

#if canImport(SwiftUI)
import SwiftUI
#endif

public extension CGRect {
	func leading(percentage: CGFloat) -> CGRect {
		precondition(percentage >= 0.0 && percentage <= 1.0)
		return CGRect(x: self.x, y: self.y, width: self.width * percentage, height: self.height)
	}

	func trailing(percentage: CGFloat) -> CGRect {
		precondition(percentage >= 0.0 && percentage <= 1.0)
		return CGRect(x: self.x + (self.width * (1.0 - percentage)), y: self.y, width: self.width * percentage, height: self.height)
	}

	func upper(percentage: CGFloat) -> CGRect {
		precondition(percentage >= 0.0 && percentage <= 1.0)
		return CGRect(x: self.x, y: self.y, width: self.width, height: self.height * percentage)
	}

	func lower(percentage: CGFloat) -> CGRect {
		precondition(percentage >= 0.0 && percentage <= 1.0)
		return CGRect(x: self.x, y: self.y + (self.height * (1.0 - percentage)), width: self.width, height: self.height * percentage)
	}

	func leading(amount: CGFloat) -> CGRect { CGRect(x: self.x, y: self.y, width: amount, height: self.height) }
	func trailing(amount: CGFloat) -> CGRect { CGRect(x: self.x + (self.width - amount), y: self.y, width: amount, height: self.height) }
	func upper(amount: CGFloat) -> CGRect { CGRect(x: self.x, y: self.y, width: self.width, height: amount) }
	func lower(amount: CGFloat) -> CGRect { CGRect(x: self.x, y: self.y + (self.height - amount), width: self.width, height: amount) }

	#if canImport(SwiftUI)
	subscript(unitPoint: UnitPoint) -> CGPoint { CGPoint(x: minX + width * unitPoint.x, y: minY + height * unitPoint.y) }
	#endif
}
