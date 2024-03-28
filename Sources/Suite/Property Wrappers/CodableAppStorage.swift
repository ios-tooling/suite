//
//  CodableAppStorage.swift
//
//
//  Created by Ben Gottlieb on 3/2/24.
//

#if canImport(SwiftUI)
import SwiftUI

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
@propertyWrapper public struct CodableAppStorage<StoredValue: Codable & Equatable>: DynamicProperty {
	public init(wrappedValue: StoredValue, _ key: String, store: UserDefaults = .standard) {
		self.key = key
		self.store = .standard
		let initialValue: StoredValue? = Self.initialValue(for: key, in: store)
		self._value = State(initialValue: initialValue ?? wrappedValue)
	}
	
	@State private var value: StoredValue
	
	private let key: String
	private let store: UserDefaults
	
	public var projectedValue: Binding<StoredValue> {
		Binding(get: { wrappedValue }, set: { new in wrappedValue = new })
	}
	
	public var wrappedValue: StoredValue {
		get { value }
		nonmutating set {
			if newValue == value { return }
			if let data = try? JSONEncoder().encode(newValue), let string = String(data: data, encoding: .utf8) {
				store.set(string, forKey: key)
				store.synchronize()
			} else {
				store.removeObject(forKey: key)
			}
			value = newValue
		}
	}
	
	static func initialValue(for key: String, in store: UserDefaults) -> StoredValue? {
		guard let string = store.object(forKey: key) as? String else { return nil }
		guard let data = string.data(using: .utf8) else { return nil }
		return try? JSONDecoder().decode(StoredValue.self, from: data)
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension CodableAppStorage {
	init<OptionalStoredValue>(_ key: String, store: UserDefaults = .standard, _ defaultValue: OptionalStoredValue? = .none) where StoredValue == Optional<OptionalStoredValue> {
		self.key = key
		self.store = store
		let initialValue = Self.initialValue(for: key, in: store)
		self._value = State(initialValue: initialValue ?? defaultValue)
	}
}
#endif
