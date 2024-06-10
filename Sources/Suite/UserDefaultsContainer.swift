//
//  UserDefaultsContainer.swift
//  
//
//  Created by Ben Gottlieb on 6/9/24.
//

import Foundation

public protocol UserDefaultsContainer {
	var userDefaults: UserDefaults { get }
}

public extension UserDefaultsContainer {
	func hasValue(for key: String) -> Bool { userDefaults.object(forKey: key) != nil }
	
	func setString(_ string: String?, for key: String) { userDefaults.setValue(string, forKey: key) }
	func string(for key: String) -> String? { userDefaults.string(forKey: key) }
	
	func setBool(_ bool: Bool, for key: String) { userDefaults.setValue(bool, forKey: key) }
	func bool(for key: String) -> Bool { userDefaults.bool(forKey: key) }
	
	func setDate(_ date: Date?, for key: String) { userDefaults.setValue(date, forKey: key) }
	func date(for key: String) -> Date? { userDefaults.object(forKey: key) as? Date }
	
	func setData(_ data: Data?, for key: String) { userDefaults.setValue(data, forKey: key) }
	func data(for key: String) -> Data? { userDefaults.data(forKey: key) }
	
	func setInt(_ int: Int, for key: String) { userDefaults.setValue(int, forKey: key) }
	func int(for key: String) -> Int { userDefaults.integer(forKey: key) }
	
	func setDouble(_ double: Double, for key: String) { userDefaults.setValue(double, forKey: key) }
	func double(for key: String) -> Double { userDefaults.double(forKey: key) }
}
