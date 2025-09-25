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

@propertyWrapper @MainActor public struct MutableObservedValue<Target: ObservableObject & Sendable, Value: Sendable>: DynamicProperty, Sendable {
	@ObservedObject var target: Target
	@State public var wrappedValue: Value?
	let get: @Sendable (Target) async -> Value
	let set: @Sendable (Target, Value?) async -> Void

	@MainActor public init(_ target: Target, get: @Sendable @escaping (Target) async -> Value, set: @Sendable @escaping (Target, Value?) async -> Void) {
		self.target = target
		self.get = get
		self.set = set
		update()
	}
	
	nonisolated public func update() {
		Task { @MainActor in
			_wrappedValue.wrappedValue = await get(target)
		}
	}
	
	@MainActor public var projectedValue: Binding<Value?> {
		.init(
			get: { wrappedValue },
			set: { value in
				Task {
					await self.set(self.target, value)
				}
			}
		)
	}
}

