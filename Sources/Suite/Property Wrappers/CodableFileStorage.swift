//
//  CodableFileStorage.swift
//
//  Created by Ben Gottlieb on 3/2/24.
//

#if canImport(SwiftUI)
import SwiftUI
import OSLog

@available(iOS 14.0, macOS 11.0, *)
fileprivate let logger = Logger(subsystem: "suite", category: "codableFileStorage")

@available(OSX 11, iOS 14.0, tvOS 14, watchOS 8, *)
@MainActor @propertyWrapper public struct CodableFileStorage<StoredValue: Codable & Sendable>: DynamicProperty {
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
				logger.error("Failed to save \(String(describing: StoredValue.self)): \(error)")
			}
			value = newValue
		}
	}
	
	func equal(_ new: StoredValue, _ old: StoredValue) -> Bool { false }
}

@available(OSX 11, iOS 14.0, tvOS 14, watchOS 8, *)
public extension CodableFileStorage {
	init<OptionalStoredValue>(_ url: URL, _ defaultValue: OptionalStoredValue? = .none) where StoredValue == Optional<OptionalStoredValue> {
		self.url = url
		let initialValue = try? StoredValue.loadJSON(file: url)
		self._value = State(initialValue: initialValue ?? defaultValue)
	}
	
}

@available(OSX 11, iOS 14.0, tvOS 14, watchOS 8, *)
public extension CodableFileStorage where StoredValue: Equatable {
	func equal(_ new: StoredValue, _ old: StoredValue) -> Bool { new == old }
}


#endif
