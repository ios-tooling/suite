//
//  Codable+Dictionary.swift
//  Suite
//
//  Created by ben on 9/9/19.
//

import Foundation

public extension JSONDictionary {
	var plist: PropertyListDictionary { self as? PropertyListDictionary ?? [:] }
}

extension Dictionary where Key == String {
	public var jsonDictionary: JSONDictionary {
		self.compactMapValues { value in
			value as? (any JSONDataType)
		}
	}
}

public extension Dictionary where Key == String {
	var jsonData: Data {
		get throws {
			try JSONSerialization.data(withJSONObject: self)
		}
	}

	var title: String? {
		self["title"] as? String ?? self["name"] as? String ?? self["description"] as? String ?? self["desc"] as? String
	}
}
