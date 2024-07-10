//
//  View+PreferenceValues.swift
//  
//
//  Created by Ben Gottlieb on 3/30/24.
//

import SwiftUI

public struct PreferenceValues: Sendable {
	public static let instance = PreferenceValues()
}

public func preferenceReduce<V>(value: inout V, nextValue: () -> V) {
}

public func preferenceReduce<V>(value: inout V?, nextValue: () -> V?) {
	value = value ?? nextValue()
}

public func preferenceReduce<V>(value: inout [V], nextValue: () -> [V]) {
		value = value + nextValue()
}

public func preferenceReduce<K, V>(value: inout [K:V], nextValue: () -> [K:V]) {
	value = value.merging(nextValue(), uniquingKeysWith: { a, b in a })
}

public extension View {
	@ViewBuilder func onPreferenceChange<K: PreferenceKey, V>(_ keyPath: KeyPath<PreferenceValues, K.Type>, _ action: @escaping (V) -> Void) -> some View where K.Value == V, V: Equatable {
		
		let key = PreferenceValues.instance[keyPath: keyPath]
		self.onPreferenceChange(key, perform: action)
	}
	
	func setPreference<K: PreferenceKey, V>(_ keyPath: KeyPath<PreferenceValues, K.Type>, _ value: V) -> some View where K.Value == V {
		
		let key = PreferenceValues.instance[keyPath: keyPath]
		return self.preference(key: key, value: value)
	}
	
	func setPreference<K: PreferenceKey>(_ keyPath: KeyPath<PreferenceValues, K.Type>, _ value: @MainActor @Sendable @escaping () async throws -> Void) -> some View where K.Value == BlockWrapper {
		
		let key = PreferenceValues.instance[keyPath: keyPath]
		return self.preference(key: key, value: BlockWrapper(block: value))
	}
	
	func setPreference<K: PreferenceKey>(_ keyPath: KeyPath<PreferenceValues, K.Type>, _ value: @MainActor @Sendable @escaping () async throws -> Void) -> some View where K.Value == BlockWrapper? {
		
		let key = PreferenceValues.instance[keyPath: keyPath]
		return self.preference(key: key, value: BlockWrapper(block: value))
	}
	
	func getPreference<K: PreferenceKey, V: Equatable>(_ keyPath: KeyPath<PreferenceValues, K.Type>, _ perform: @escaping (V) -> Void) -> some View where K.Value == V {
		
		let key = PreferenceValues.instance[keyPath: keyPath]
		return self.onPreferenceChange(key, perform: perform)
		
	}
	
	func getPreferenceClosure<K: PreferenceKey>(_ keyPath: KeyPath<PreferenceValues, K.Type>, _ perform: @escaping (() async throws -> Void) -> Void) -> some View where K.Value == BlockWrapper {
		
		let key = PreferenceValues.instance[keyPath: keyPath]
		return self.onPreferenceChange(key) { pref in
			perform(pref.block)
		}
	}
	
	
	func getPreferenceClosure<K: PreferenceKey>(_ keyPath: KeyPath<PreferenceValues, K.Type>, _ perform: @escaping ((@Sendable () async throws -> Void)?) -> Void) -> some View where K.Value == BlockWrapper? {
		
		let key = PreferenceValues.instance[keyPath: keyPath]
		return self.onPreferenceChange(key) { pref in
			perform(pref?.block)
		}
	}
}
