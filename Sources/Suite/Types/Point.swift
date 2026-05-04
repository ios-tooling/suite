//
//  Point.swift
//  
//
//  Created by Ben Gottlieb on 7/11/21.
//

import Foundation

public struct Point: Equatable, Hashable, Codable, Sendable {
	public var x: Int
	public var y: Int

	public init(_ x: Int, _ y: Int) {
		self.x = x
		self.y = y
	}
}
