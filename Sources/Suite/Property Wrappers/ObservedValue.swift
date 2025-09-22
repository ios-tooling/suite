//
//  ObservedValue.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/21/25.
//

import SwiftUI

@propertyWrapper @MainActor public struct ObservedValue<Target: ObservableObject & Sendable, Value: Sendable>: DynamicProperty, Sendable {
	@ObservedObject var target: Target
	@State public var wrappedValue: Value?
	let closure: @Sendable (Target) async -> Value
	
	@MainActor public init(_ target: Target, _ closure: @Sendable @escaping (Target) async -> Value) {
		self.target = target
		self.closure = closure
		update()
	}
	
	nonisolated public func update() {
		Task { @MainActor in
			_wrappedValue.wrappedValue = await closure(target)
		}
	}
}

