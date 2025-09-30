//
//  CGPoint.swift
//  
//
//  Created by Ben Gottlieb on 3/20/21.
//

import Foundation
import CoreGraphics

public extension CGPoint {
	var size: CGSize { CGSize(width: x, height: y )}
	
	func centeredRect(size: CGSize) -> CGRect {
		CGRect(x: self.x - size.width / 2, y: self.y - size.height / 2, width: size.width, height: size.height)
	}
	
	func centeredRect(size: Double) -> CGRect {
		centeredRect(size: CGSize(width: size, height: size))
	}
	
	func square(side: CGFloat) -> CGRect { self.centeredRect(size: CGSize(width: side, height: side)) }
	
	func adjustX(_ deltaX: CGFloat) -> CGPoint {  CGPoint(x: self.x + deltaX, y: self.y) }
	func adjustY(_ deltaY: CGFloat) -> CGPoint {  CGPoint(x: self.x, y: self.y + deltaY) }
		
	func nearestPoint(on line: CGLine) -> CGPoint {
		let A = x - line.start.x
		let B = y - line.start.y
		let C = (line.vector.x)
		let D = (line.vector.y)
		let sqLen = C * C + D * D
		let dot = A * C + B * D
		let distanceFactor = sqLen == 0 ? -1 : dot / sqLen
		if distanceFactor < 0 {
			return line.start
		} else if distanceFactor > 1 {
			return line.end
		}
		return CGPoint(line.start.x + distanceFactor * line.vector.x, line.start.y + distanceFactor * line.vector.y)
	}
	
	func distance(to line: CGLine) -> CGFloat {
		nearestPoint(on: line).distance(to: self)
	}
	
	func close(to point: CGPoint, tolerance: CGFloat) -> Bool {
		let delta = point - self
		
		return abs(delta.x) <= tolerance && abs(delta.y) <= tolerance
	}
}

extension CGPoint: @retroactive Hashable {}
extension CGPoint: StringInitializable, @retroactive RawRepresentable { }
extension CGPoint: @retroactive CustomStringConvertible { }
