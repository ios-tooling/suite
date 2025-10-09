//
//  vprint.swift
//  Suite
//
//  Created by Ben Gottlieb on 10/9/25.
//

#if canImport(SwiftUI)
import SwiftUI

public func vprint<Content>(_ content: Content, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> some View {
	print("\(file) \(function):\(line)")
	print(content)
	return EmptyView()
}

#endif
