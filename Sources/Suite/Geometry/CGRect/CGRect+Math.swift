//
//  CGRect+Math.swift
//
//
//  Created by Ben Gottlieb on 12/2/19.
//

import Foundation
import CoreGraphics

#if os(macOS)
import AppKit
#endif

public extension CGRect {
	var largestDimension: CGFloat { max(width, height) }
	var smallestDimension: CGFloat { min(width, height) }

	init(x: CGFloat = 0, y: CGFloat = 0, size: CGSize) {
		self.init(x: x, y: y, width: size.width, height: size.height)
	}

	init(origin: CGPoint, width: CGFloat, height: CGFloat) {
		self.init(x: origin.x, y: origin.y, width: width, height: height)
	}

	#if os(macOS)
	func inset(by insets: NSEdgeInsets) -> CGRect {
		CGRect(x: origin.x + insets.left, y: origin.y + insets.top, width: width - (insets.left + insets.right), height: height - (insets.top + insets.bottom))
	}
	#endif

	var aspectRatio: CGFloat { return self.size.aspectRatio }
	var aspectRatioType: CGSize.AspectRatioType { return self.size.aspectRatioType }

	var x: CGFloat {
		set { self.origin.x = newValue }
		get { return self.origin.x }
	}

	var y: CGFloat {
		set { self.origin.y = newValue }
		get { return self.origin.y }
	}

	var center: CGPoint { CGPoint(x: self.midX, y: self.midY) }

	var upperLeft: CGPoint { CGPoint(x: self.minX, y: self.minY) }
	var upperRight: CGPoint { CGPoint(x: self.maxX, y: self.minY) }
	var lowerLeft: CGPoint { CGPoint(x: self.minX, y: self.maxY) }
	var lowerRight: CGPoint { CGPoint(x: self.maxX, y: self.maxY) }

	var allPoints: [CGPoint] {
		var results: [CGPoint] = []

		for y in Int(upperLeft.y)..<Int(lowerRight.y) {
			for x in Int(upperLeft.x)..<Int(lowerRight.x) {
				results.append(CGPoint(x: x, y: y))
			}
		}
		return results
	}

	func rounded() -> CGRect {
		CGRect(x: roundcgf(value: self.origin.x), y: roundcgf(value: self.origin.y), width: roundcgf(value: self.width + (self.origin.x - roundcgf(value: self.origin.x))), height: roundcgf(value: self.height + (self.origin.y - roundcgf(value: self.origin.y))))
	}

	func scaled(to factor: CGFloat) -> CGRect {
		CGRect(x: self.x * factor, y: self.y * factor, width: self.width * factor, height: self.height * factor)
	}

	func scaledRectWithAspectRatio(ratio: CGFloat) -> CGRect {
		var width = self.width, height = self.height

		if width / ratio < height {
			height = width / ratio
		} else {
			width = height * ratio
		}

		return CGRect(x: (self.width - width) / 2, y: (self.height - height) / 2, width: width, height: height)
	}

	func flippedVertically(in frame: CGRect) -> CGRect {
		CGRect(x: self.origin.x, y: frame.height - (self.origin.y + self.height), size: self.size)
	}

	func offset(x: CGFloat = 0, y: CGFloat = 0) -> CGRect {
		CGRect(x: self.origin.x + x, y: self.origin.y + y, width: self.width, height: self.height)
	}

	func centerVertically(height: CGFloat) -> CGRect {
		let delta = (self.height - height) / 2
		return CGRect(x: self.x, y: self.y + delta, width: self.width, height: height)
	}
}
