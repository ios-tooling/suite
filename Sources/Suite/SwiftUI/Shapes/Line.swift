//
//  Line.swift
//  Suite
//
//  Created by Ben Gottlieb on 8/19/25.
//

import SwiftUI

public struct Line: Shape {
	var horizontal = true
	public init(horizontal: Bool = true) {
		self.horizontal = horizontal
	}
	
	public func path(in rect: CGRect) -> Path {
		var path = Path()
		
		if horizontal {
			path.move(to: CGPoint(x: rect.minX, y: rect.midY))
			path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
		} else {
			path.move(to: CGPoint(x: rect.midX, y: rect.minY))
			path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
		}
		return path
	}
}
