//
//  DiskBackedDictionary.swift
//  Suite
//
//  Created by Ben Gottlieb on 5/1/26.
//


public struct DiskBackedDictionary<Key: Hashable & Codable, Value: Codable> {
	let cacheURL: URL
	let encoder: JSONEncoder
	let decoder: JSONDecoder
	let writer: DiskBackedFileWriter
	
	var cache: [Key: Value] = [:]
	
	public subscript(_ key: Key) -> Value? {
		get { cache[key] }
		set {
			if let newValue {
				cache[key] = newValue
				save()
			} else if cache[key] != nil {
				cache.removeValue(forKey: key)
				save()
			}
		}
	}

	public subscript(_ key: Key, `default` def: Value) -> Value {
		get { cache[key] ?? def }
		set {
			cache[key] = newValue
			save()
		}
	}

	public var keys: Dictionary<Key, Value>.Keys { cache.keys }
	public var values: Dictionary<Key, Value>.Values { cache.values }
	public var snapshot: [Key: Value] { cache }
	public var isEmpty: Bool { cache.isEmpty }
	public var count: Int { cache.count }

	public mutating func remove(_ key: Key) {
		if cache.removeValue(forKey: key) != nil { save() }
	}

	public mutating func removeAll() {
		guard !cache.isEmpty else { return }
		cache.removeAll()
		save()
	}

	/// Pass `loadsFromDisk: false` when `cache` has already been read — see
	/// `loading(from:)`, which does that read off the calling thread.
	public init(cacheURL: URL, encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init(), cache: [Key: Value] = [:], loadsFromDisk: Bool = true) {
		self.cacheURL = cacheURL
		self.decoder = decoder
		self.encoder = encoder
		self.cache = cache
		self.writer = .init(url: cacheURL)
		
		guard loadsFromDisk else { return }
		try? FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
		if let data = try? Data(contentsOf: cacheURL) {
			self.cache = (try? decoder.decode([Key: Value].self, from: data)) ?? [:]
		}
	}
	
	/// Writes anything still waiting on the coalescing timer. Backgrounding and
	/// termination already do this; call it when you need the file up to date now.
	public func flushToDisk() {
		writer.writePendingData()
	}
	
	func save() {
		do {
			let data = try encoder.encode(cache)
			writer.save(data)
		} catch {
			if #available(iOS 16, macOS 14, tvOS 16, watchOS 9, *) {
				print("Failed to write [\(String(describing: Key.self)):\(String(describing: Value.self)) to \(cacheURL.path(percentEncoded: false)): \(error.localizedDescription)")
			} else {
				print("Failed to write [\(String(describing: Key.self)):\(String(describing: Value.self)) to \(cacheURL): \(error.localizedDescription)")
			}
		}
	}
}

extension DiskBackedDictionary: Equatable where Key: Equatable, Value: Equatable {
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.cache == rhs.cache
	}
}

extension DiskBackedDictionary where Value: Equatable {
	public subscript(_ key: Key, `default` def: Value) -> Value {
		get { cache[key] ?? def }
		set {
			if cache[key] == newValue { return }
			cache[key] = newValue
			save()
		}
	}

	public subscript(_ key: Key) -> Value? {
		get { cache[key] }
		set {
			if let newValue {
				if cache[key] == newValue { return }
				cache[key] = newValue
				save()
			} else if cache[key] != nil {
				cache.removeValue(forKey: key)
				save()
			}
		}
	}

}
