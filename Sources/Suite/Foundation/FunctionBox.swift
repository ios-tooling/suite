//
//  FunctionBox.swift
//  Suite
//
//  Created by Ben Gottlieb on 12/21/25.
//

import Foundation

public struct FunctionBox: Hashable, Equatable {
	let line: Int
	let file: String
	let function: String
	
	let closure: () -> Void
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(file)
		hasher.combine(function)
		hasher.combine(line)
	}
	
	public static func == (lhs: FunctionBox, rhs: FunctionBox) -> Bool {
		lhs.file == rhs.file && lhs.function == rhs.function && lhs.line == rhs.line
	}
	
	public init(file: String = #file, function: String = #function, line: Int = #line, closure: @escaping () -> Void) {
		self.file = file
		self.function = function
		self.line = line
		
		self.closure = closure
	}
	
	public func callAsFunction() {
		closure()
	}
}
