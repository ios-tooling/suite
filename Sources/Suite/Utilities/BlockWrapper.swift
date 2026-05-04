//
//  BlockWrapper.swift
//  
//
//  Created by Ben Gottlieb on 3/17/24.
//

import Foundation

/// A `Sendable` wrapper around an async-throwing block. Equality is based on the source location at which the wrapper was created (`#file`/`#line`/`#column`), so two `BlockWrapper`s constructed at the same call site compare equal regardless of their captured closure contents — useful for de-duplicating subscriptions registered from the same site.
public struct BlockWrapper: Sendable, Equatable {
	let file: String
	let line: Int
	let column: Int
	public let block: @Sendable () async throws -> Void
	
	public init(file: String = #file, line: Int = #line, col: Int = #column, block: @Sendable @escaping () async throws -> Void) {
		self.file = file
		self.line = line
		self.column = col
		self.block = block
	}
	
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.line == rhs.line && lhs.file == rhs.file && lhs.column == rhs.column
	}
}

