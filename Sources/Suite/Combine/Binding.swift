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

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension Binding {
	func onChange(_ completion: @escaping (Value) -> Void) -> Binding<Value> {
		Binding<Value>(get: { self.wrappedValue }, set: { newValue in
			self.wrappedValue = newValue
			completion(newValue)
		})
	}

	func willChange(_ completion: @escaping (Value) -> Void) -> Binding<Value> {
		Binding<Value>(get: { self.wrappedValue }, set: { newValue in
			completion(newValue)
			self.wrappedValue = newValue
		})
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension Binding where Value: Equatable {
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
}
extension Optional: OptionalType {
	public var isEmpty: Bool {
		switch self {
		case .none: return true
		default: return false
		}
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension Binding where Value: OptionalType {
	var bool: Binding<Bool> {
		Binding<Bool>(get: { !wrappedValue.isEmpty }, set: { _ in })
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension Binding {
	var optional: Binding<Value?> {
		Binding<Value?>(get: { self.wrappedValue }, set: { opt in
			if let val = opt { self.wrappedValue = val }
		})
	}
	
	init<T>(isNotNil source: Binding<T?>, defaultValue: T) where Value == Bool {
		self.init(get: { source.wrappedValue != nil }, set: { source.wrappedValue = $0 ? defaultValue : nil })
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension Binding where Value == Bool {
	var inverted: Binding<Bool> { Binding<Bool>(get: { !self.wrappedValue }, set: { newValue in self.wrappedValue = !newValue
	}) }
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public class Bound<Value> {
	public init(_ initial: Value) {
		value = initial
	}
	public var value: Value
	
	public var binding: Binding<Value> {
		Binding<Value>(get: { self.value }, set: { self.value = $0 })
	}
}


#endif
#endif
