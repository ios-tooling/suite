//
//  StructHashing.swift
//  DataModel
//
//  Created by Ben Gottlieb on 9/23/24.
//  Copyright © 2024 DetectionTek. All rights reserved.
//

public extension Encodable where Self: Decodable {
	func stableMD5(using encoder: JSONEncoder = .default) throws -> String {
		let json: JSONDictionary = try self.asJSON(using: encoder)
		
		return try json.stableJSONMD5
	}
}

public extension JSONDictionary {
	var stableJSONMD5: String { get throws { try stableMD5 } }
	var stableMD5: String {
		get throws {
			var keyHashes: [KeyHash] = []
			
			for (key, value) in self {
				if let bool = value as? Bool {
					try keyHashes.append(.init(key: key, hash: String(describing: bool).md5))
				} else if let int = value as? Int {
					try keyHashes.append(.init(key: key, hash: String(describing: int).md5))
				} else if let string = value as? String {
					try keyHashes.append(.init(key: key, hash: string.md5))
				} else if let float = value as? Float {
					try keyHashes.append(.init(key: key, hash: String(describing: float).md5))
				} else if let double = value as? Double {
					try keyHashes.append(.init(key: key, hash: String(describing: double).md5))
				} else if let date = value as? Date {
					try keyHashes.append(.init(key: key, hash: String(describing: date.timeIntervalSinceReferenceDate).md5))
				} else if let data = value as? Data {
					try keyHashes.append(.init(key: key, hash: data.md5))
				} else if let dict = value as? JSONDictionary {
					try keyHashes.append(.init(key: key, hash: dict.stableMD5))
				} else if let array = value as? [(any JSONDataType)] {
					try keyHashes.append(.init(key: key, hash: array.stableMD5))
				}
			}
			
			let sorted = keyHashes.sorted()
			let concat = sorted.reduce("") { combined, individual in combined + (individual.hash ?? "") }
			
			return try concat.md5
		}
	}
}

enum StableMD5Error: LocalizedError { case unknownType(Sendable)
	var errorDescription: String? {
		switch self {
		case .unknownType(let what): "Unknown JSON Data: \(what)"
		}
	}
}

public extension [any JSONDataType] {
	var stableMD5: String {
		get throws {
			let md5s: [String] = try self.compactMap { value -> String in
				if let bool = value as? Bool {
					try String(describing: bool).md5
				} else if let int = value as? Int {
					try String(describing: int).md5
				} else if let string = value as? String {
					try string.md5
				} else if let float = value as? Float {
					try String(describing: float).md5
				} else if let double = value as? Double {
					try String(describing: double).md5
				} else if let date = value as? Date {
					try String(describing: date).md5
				} else if let data = value as? Data {
					try data.md5
				} else if let dict = value as? JSONDictionary {
					try dict.stableMD5
				} else if let array = value as? [(any JSONDataType)] {
					try array.stableMD5
				} else {
					throw StableMD5Error.unknownType(value)
				}
			}
			
			let concat = md5s.reduce("") { combined, individual in combined + individual }
			
			return try concat.md5
		}
	}
}

struct KeyHash: Comparable {
	let key: String
	let hash: String?
	static func <(lhs: Self, rhs: Self) -> Bool { lhs.key < rhs.key }
}
