//
//  JSONDecoder.swift
//  Suite
//
//  Created by Ben Gottlieb on 3/15/26.
//

import Foundation

public extension JSONDecoder {
	func decode<T: Decodable>(_ type: T.Type, optional data: Data?) throws -> T? {
		guard let data else { return nil }
		return try decode(T.self, from: data)
	}
}
