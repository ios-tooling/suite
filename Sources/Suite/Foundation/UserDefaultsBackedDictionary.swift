//
//  UserDefaultsBackedDictionary.swift
//  
//
//  Created by Ben Gottlieb on 4/12/20.
//

import Foundation

public protocol UserDefaultStorable { }

extension String: UserDefaultStorable {}
extension Date: UserDefaultStorable {}
extension Data: UserDefaultStorable {}
extension Int: UserDefaultStorable {}
extension Double: UserDefaultStorable {}
extension URL: UserDefaultStorable {}
extension Float: UserDefaultStorable {}
extension Dictionary: UserDefaultStorable where Key == String, Value: UserDefaultStorable {}
extension Array: UserDefaultStorable where Element: UserDefaultStorable {}

public protocol StringConvertible {
	var string: String { get }
}

extension String: StringConvertible {
	public var string: String { return self }
}

public protocol KeyValueContainer {
	associatedtype Key: StringConvertible
	associatedtype Value: UserDefaultStorable
	
	subscript(key: Key) -> Value? { get set }
}

public struct UserDefaultsBackedDictionary<Key: StringConvertible, Value: UserDefaultStorable>: KeyValueContainer {
	let defaults: UserDefaults
	let converter: (Key) -> String
	
	public init(defaults: UserDefaults = .standard, converter: @escaping (Key) -> String = { key in key.string }) {
		self.defaults = defaults
		self.converter = converter
	}
	
	public func removeValue(forKey key: Key) {
		defaults.removeValue(forKey: string(from: key))
	}
	
	func string(from key: Key) -> String { return converter(key) }
	public subscript(key: Key) -> Value? {
		get {
			let storageKey = string(from: key)
			if Value.self == URL.self { return defaults.url(forKey: storageKey) as? Value }
			return defaults.value(forKey: storageKey) as? Value
		}
		set {
			let storageKey = string(from: key)
			if let value = newValue {
				if let url = value as? URL {
					self.defaults.set(url, forKey: storageKey)
				} else {
					self.defaults.set(value, forKey: storageKey)
				}
			} else {
				self.defaults.removeValue(forKey: storageKey)
			}
		}
	}
}
