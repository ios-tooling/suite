//
//  CodableFileStorage.swift
//
//  Created by Ben Gottlieb on 3/2/24.
//

#if canImport(SwiftUI)
import SwiftUI

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
@propertyWrapper public struct CodableFileStorage<StoredValue: Codable>: DynamicProperty {
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
			if equal(newValue, value) { return }
			
			do {
				let data = try JSONEncoder().encode(newValue)
				if data == "null".data(using: .utf8) {
					try? FileManager.default.removeItem(at: url)
				} else {
					try? data.write(to: url)
				}
			} catch {
				print("Failed to save: \(error)")
			}
			value = newValue
		}
	}
	
	func equal(_ new: StoredValue, _ old: StoredValue) -> Bool { false }
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension CodableFileStorage {
	init<OptionalStoredValue>(_ url: URL, _ defaultValue: OptionalStoredValue? = .none) where StoredValue == Optional<OptionalStoredValue> {
		self.url = url
		let initialValue = try? StoredValue.loadJSON(file: url)
		self._value = State(initialValue: initialValue ?? defaultValue)
	}
	
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension CodableFileStorage where StoredValue: Equatable {
	func equal(_ new: StoredValue, _ old: StoredValue) -> Bool { new == old }
}


#endif
