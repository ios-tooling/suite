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

extension UserDefaultsContainer {
	subscript(string key: String) -> String? {
		get { userDefaults.string(forKey: key) }
		set { userDefaults.setValue(newValue, forKey: key)}
	}
	
	subscript(double key: String) -> Double? {
		get { userDefaults.double(forKey: key) }
		set { userDefaults.setValue(newValue, forKey: key)}
	}
	
	subscript(int key: String) -> Int? {
		get { userDefaults.integer(forKey: key) }
		set { userDefaults.setValue(newValue, forKey: key)}
	}
	
	subscript(data key: String) -> Data? {
		get { userDefaults.data(forKey: key) }
		set { userDefaults.setValue(newValue, forKey: key)}
	}
	
	subscript(date key: String) -> Date? {
		get { userDefaults.object(forKey: key) as? Date }
		set { userDefaults.setValue(newValue, forKey: key)}
	}
}
