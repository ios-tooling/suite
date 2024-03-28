//
//  CodableFileStorage.swift
//
//  Created by Ben Gottlieb on 3/2/24.
//

#if canImport(SwiftUI)
import SwiftUI

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
@propertyWrapper public struct CodableFileStorage<StoredValue: Codable & Equatable>: DynamicProperty {
	public init(wrappedValue: StoredValue, _ url: URL) {
		self.url = url
		let initialValue = try? StoredValue.loadJSON(file: url)
		self._value = State(initialValue: initialValue ?? wrappedValue)
	}
	
	@State private var value: StoredValue
	
	private let url: URL
	
	public var projectedValue: Binding<StoredValue> {
		Binding(get: { wrappedValue }, set: { new in wrappedValue = new })
	}
	
	public var wrappedValue: StoredValue {
		get { value }
		nonmutating set {
			if newValue == value { return }
			try? newValue.saveJSON(to: url)
			value = newValue
		}
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension CodableFileStorage {
	init<OptionalStoredValue>(_ url: URL, _ defaultValue: OptionalStoredValue? = .none) where StoredValue == Optional<OptionalStoredValue> {
		self.url = url
		let initialValue = try? StoredValue.loadJSON(file: url)
		self._value = State(initialValue: initialValue ?? defaultValue)
	}
}
#endif
