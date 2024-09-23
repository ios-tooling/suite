//
//  StructHashing.swift
//  DataModel
//
//  Created by Ben Gottlieb on 9/23/24.
//  Copyright © 2024 DetectionTek. All rights reserved.
//

public extension Encodable where Self: Decodable {
	func stableMD5(using encoder: JSONEncoder = .default) -> String? {
		guard let json: [String: (any JSONDataType)] = try? self.asJSON(using: encoder) else { return nil }
		
		return json.stableJSONMD5
	}
}

public extension [String: any JSONDataType] {
	var stableJSONMD5: String? { stableMD5 }
	var stableMD5: String? {
		var keyHashes: [KeyHash] = []
		
		for (key, value) in self {
			if let bool = value as? Bool {
				keyHashes.append(.init(key: key, hash: String(describing: bool).md5))
			} else if let int = value as? Int {
				keyHashes.append(.init(key: key, hash: String(describing: int).md5))
			} else if let string = value as? String {
				keyHashes.append(.init(key: key, hash: string.md5))
			} else if let float = value as? Float {
				keyHashes.append(.init(key: key, hash: String(describing: float).md5))
			} else if let double = value as? Double {
				keyHashes.append(.init(key: key, hash: String(describing: double).md5))
			} else if let date = value as? Date {
				keyHashes.append(.init(key: key, hash: String(describing: date).md5))
			} else if let data = value as? Data {
				keyHashes.append(.init(key: key, hash: data.md5))
			} else if let dict = value as? [String: (any JSONDataType)] {
				keyHashes.append(.init(key: key, hash: dict.stableMD5))
			} else if let array = value as? [(any JSONDataType)] {
				keyHashes.append(.init(key: key, hash: array.stableMD5))
			}
		}
		
		let sorted = keyHashes.sorted()
		let concat = sorted.reduce("") { combined, individual in combined + (individual.hash ?? "") }
		
		return concat.md5
	}
}

public extension [any JSONDataType] {
	var stableMD5: String? {
		let md5s: [String] = self.compactMap { value -> String? in
			if let bool = value as? Bool {
				String(describing: bool).md5
			} else if let int = value as? Int {
				String(describing: int).md5
			} else if let string = value as? String {
				string.md5
			} else if let float = value as? Float {
				String(describing: float).md5
			} else if let double = value as? Double {
				String(describing: double).md5
			} else if let date = value as? Date {
				String(describing: date).md5
			} else if let data = value as? Data {
				data.md5
			} else if let dict = value as? [String: (any JSONDataType)] {
				dict.stableMD5
			} else if let array = value as? [(any JSONDataType)] {
				array.stableMD5
			} else {
				nil
			}
		}
		
		let concat = md5s.reduce("") { combined, individual in combined + individual }
		
		return concat.md5
	}
}

struct KeyHash: Comparable {
	let key: String
	let hash: String?
	static func <(lhs: Self, rhs: Self) -> Bool { lhs.key < rhs.key }
}
