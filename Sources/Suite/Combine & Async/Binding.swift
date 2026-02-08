//
//  Binding.swift
//  InternalUI
//
//  Created by Ben Gottlieb on 2/19/20.
//

#if canImport(SwiftUI)
import SwiftUI
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public func ??<T: Sendable>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension Binding where Value: Equatable & Sendable {
	init(_ source: Binding<Value?>, nilValue: Value) {
		self.init(
			get: { source.wrappedValue ?? nilValue },
			set: { newValue in
				if newValue == nilValue {
					source.wrappedValue = nil
				} else {
					source.wrappedValue = newValue
				}
			})
	}
}

public protocol OptionalType {
	var isEmpty: Bool { get }
	mutating func clear()
}
extension Optional: OptionalType {
	public mutating func clear() {
		self = .none
	}
	public var isEmpty: Bool {
		switch self {
		case .none: return true
		default: return false
		}
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
@MainActor public extension Binding where Value: OptionalType {
	var bool: Binding<Bool> {
		Binding<Bool>(get: { !wrappedValue.isEmpty }, set: { newValue in
			if !newValue { wrappedValue.clear() }
		})
	}
	
	func bool(default defaultValue: Value) -> Binding<Bool>{
		Binding<Bool>(get: { !wrappedValue.isEmpty }, set: { newValue in
			if newValue {
				wrappedValue = defaultValue
			} else {
				wrappedValue.clear()
			}
		})
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension Binding where Value: Sendable {
	var optional: Binding<Value?> {
		Binding<Value?>(get: { self.wrappedValue }, set: { opt in
			if let val = opt { self.wrappedValue = val }
		})
	}
	
	init<T: Sendable>(isNotNil source: Binding<T?>, defaultValue: T) where Value == Bool {
		self.init(get: { source.wrappedValue != nil }, set: { source.wrappedValue = $0 ? defaultValue : nil })
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension Binding where Value == Bool {
	var inverted: Binding<Bool> { Binding<Bool>(get: { !self.wrappedValue }, set: { newValue in self.wrappedValue = !newValue
	}) }
	
	init(_ boolProvider: @Sendable @autoclosure @escaping () -> Bool) {
		self.init(get: boolProvider, set: { _ in })
	}
}

public extension Binding where Value: Equatable & Sendable {
	func equalTo(_ element: Value) -> Binding<Bool> {
		Binding<Bool>(
			get: { wrappedValue == element },
			set: { newValue in if newValue { wrappedValue = element }}
		)
	}
}

#endif
