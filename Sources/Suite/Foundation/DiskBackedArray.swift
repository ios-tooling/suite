//
//  DiskBackedArray.swift
//  Suite
//
//  Created by Ben Gottlieb on 5/1/26.
//


public struct DiskBackedArray<Value: Codable> {
	let cacheURL: URL
	let encoder: JSONEncoder
	let decoder: JSONDecoder
	
	var cache: [Value] = []
	
	public subscript(_ index: Int) -> Value {
		get { cache[index] }
		set {
			cache[index] = newValue
			save()
		}
	}
	
	public init(cacheURL: URL, encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init(), cache: [Value] = []) {
		self.cacheURL = cacheURL
		self.decoder = decoder
		self.encoder = encoder
		self.cache = cache
		
		try? FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
		if let data = try? Data(contentsOf: cacheURL) {
			self.cache = (try? decoder.decode([Value].self, from: data)) ?? []
		}
	}
	
	func save() {
		do {
			let data = try encoder.encode(cache)
			try data.write(to: cacheURL, options: .atomic)
		} catch {
			if #available(iOS 16, macOS 14, tvOS 16, watchOS 9, *) {
				print("Failed to write [\(String(describing: Value.self)) to \(cacheURL.path(percentEncoded: false)): \(error.localizedDescription)")
			} else {
				print("Failed to write [\(String(describing: Value.self)) to \(cacheURL): \(error.localizedDescription)")
			}
		}
	}
	
	public var values: [Value] { cache }
	public var snapshot: [Value] { cache }
	public var isEmpty: Bool { cache.isEmpty }
	public var count: Int { cache.count }

	public mutating func removeAll() {
		guard !cache.isEmpty else { return }
		cache.removeAll()
		save()
	}

}

extension DiskBackedArray where Value: Equatable {
	public subscript(_ index: Int) -> Value {
		get { cache[index] }
		set {
			if cache[index] == newValue { return }
			cache[index] = newValue
			save()
		}
	}
}
