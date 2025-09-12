//
//  Binding.swift
//  InternalUI
//
//  Created by Ben Gottlieb on 2/19/20.
//

#if canImport(SwiftUI)
#if canImport(Combine)
import SwiftUI
import Combine

//@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
//public extension Binding {
//	func onChange(_ completion: @escaping (Value) -> Void) -> Binding<Value> {
//		Binding<Value>(get: { self.wrappedValue }, set: { newValue in
//			self.wrappedValue = newValue
//			completion(newValue)
//		})
//	}
//
//	func onChange(_ completion: @escaping (Value, Value) -> Void) -> Binding<Value> {
//		Binding<Value>(get: { self.wrappedValue }, set: { newValue in
//			let oldValue = self.wrappedValue
//			self.wrappedValue = newValue
//			completion(oldValue, newValue)
//		})
//	}
//
//	func willChange(_ completion: @escaping (Value) -> Void) -> Binding<Value> {
//		Binding<Value>(get: { self.wrappedValue }, set: { newValue in
//			completion(newValue)
//			self.wrappedValue = newValue
//		})
//	}
//}

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

//@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
//public class Bound<Value: Sendable> {
//	public init(_ initial: Value) {
//		value = initial
//	}
//	public var value: Value
//	
//	public var binding: Binding<Value> {
//		Binding<Value>(get: { self.value }, set: { self.value = $0 })
//	}
//}

public extension Binding where Value: Equatable & Sendable {
	func equalTo(_ element: Value) -> Binding<Bool> {
		Binding<Bool>(
			get: { wrappedValue == element },
			set: { newValue in if newValue { wrappedValue = element }}
		)
	}
}

#endif
#endif
