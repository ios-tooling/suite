//
//  NavigationPath.swift
//  Suite
//
//  Created by Ben Gottlieb on 2/26/25.
//

import SwiftUI

@available(iOS 16.0, macOS 13, watchOS 9, *)
public extension NavigationPath {
	mutating func popToRoot() {
		popToIndex(0)
	}
	
	mutating func popToIndex(_ index: Int) {
		while count > index { self.removeLast() }
	}
}

@available(iOS 16.0, macOS 13, watchOS 9, *)
public extension Binding<NavigationPath> {
	func append<V: Hashable>(_ value: V) {
		wrappedValue.append(value)
	}
	
	func removeLast() {
		wrappedValue.removeLast()
	}
	
	func popToRoot() {
		wrappedValue.popToRoot()
	}
	
	func popToIndex(_ index: Int) {
		wrappedValue.popToIndex(index)
	}
	
	var count: Int { wrappedValue.count }
}
