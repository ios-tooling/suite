//
//  CodableJSONArray.swift
//
//
//  Created by Ben Gottlieb on 3/2/24.
//

import Foundation

public struct CodableJSONArray: Codable, Equatable, Hashable, Sendable {
	public static func == (lhs: CodableJSONArray, rhs: CodableJSONArray) -> Bool {
		compareTwoJSONArrays(lArray: lhs.backing, rArray: rhs.backing)
	}
	
	public var array: [Sendable] { backing }
	
	public init() { backing = [] }
	public static let empty = CodableJSONArray()
	
	public subscript(index: Int) -> Sendable {
		get { backing[index] }
		set {
			backing[index] = newValue
		}
	}
	
	public func hash(into hasher: inout Hasher) {
		for index in backing.indices {
			hasher.combine(index)
			if let hash = backing[index] as? any Hashable {
				hasher.combine(hash)
			}
		}
	}
	
	var backing: [Sendable]
	
	public init(_ json: [Sendable]) {
		backing = json.filter { value in
			value is (any JSONDataType)
		}
	}
	
	public init?(_ json: [String: Sendable]?) {
		guard let json else { return nil }
		self.init(json)
	}
	
	public init(from decoder: Decoder) throws {
		var container = try decoder.unkeyedContainer()
		
		backing = try container.decodeJSONArray()
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.unkeyedContainer()
		try container.encode(backing)
	}
}

extension CodableJSONArray: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: (Sendable)...) {
		let array = elements.reduce(into: []) { $0.append($1) }
		
		self.init(array)
	}
}
