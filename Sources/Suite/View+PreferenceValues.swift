//
//  View+PreferenceValues.swift
//  
//
//  Created by Ben Gottlieb on 3/30/24.
//

import SwiftUI

public struct PreferenceValues {
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
	func setPreference<K: PreferenceKey, V>(_ keyPath: KeyPath<PreferenceValues, K.Type>, _ value: V) -> some View where K.Value == V {
		
		let key = PreferenceValues.instance[keyPath: keyPath]
		return self.preference(key: key, value: value)
	}
	
	func getPreference<K: PreferenceKey, V: Equatable>(_ keyPath: KeyPath<PreferenceValues, K.Type>, _ perform: @escaping (V) -> Void) -> some View where K.Value == V {
		
		let key = PreferenceValues.instance[keyPath: keyPath]
		return self.onPreferenceChange(key, perform: perform)

	}
}
