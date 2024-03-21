//
//  BlockWrapper.swift
//  
//
//  Created by Ben Gottlieb on 3/17/24.
//

import Foundation

public struct BlockWrapper<Arg, Result>: Sendable, Equatable {
	let file: String
	let line: Int
	let column: Int
	public let block: @Sendable (Arg) -> Result
	
	public init(file: String = #file, line: Int = #line, col: Int = #column, block: @Sendable @escaping (Arg) -> Result) {
		self.file = file
		self.line = line
		self.column = col
		self.block = block
	}
	
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.line == rhs.line && lhs.file == rhs.file && lhs.column == rhs.column
	}
}

