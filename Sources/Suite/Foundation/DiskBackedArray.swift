//
//  DiskBackedArray.swift
//  Suite
//
//  Created by Ben Gottlieb on 5/1/26.
//


public struct DiskBackedArray<Element: Codable>: ExpressibleByArrayLiteral {
	let cacheURL: URL
	let encoder: JSONEncoder
	let decoder: JSONDecoder
	let uniqueElements: Bool
	
	var cache: [Element] = []
	
	public subscript(_ index: Int) -> Element {
		get { cache[index] }
		set {
			cache[index] = newValue
			save()
		}
	}
	
	public init(arrayLiteral elements: Element...) {
		self.cacheURL = URL.caches.appendingPathComponent("\(String(describing: Element.self))_cache.json")
		self.encoder = .init()
		self.decoder = .init()
		self.uniqueElements = true
		self.cache = elements
	}
	
	
	public init(cacheURL: URL, encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init(), cache: [Element] = [], uniqueElements: Bool = true) {
		self.cacheURL = cacheURL
		self.decoder = decoder
		self.encoder = encoder
		self.cache = cache
		self.uniqueElements = uniqueElements
		
		try? FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
		if let data = try? Data(contentsOf: cacheURL) {
			self.cache = (try? decoder.decode([Element].self, from: data)) ?? []
		}
	}
	
	func save() {
		do {
			let data = try encoder.encode(cache)
			try data.write(to: cacheURL, options: .atomic)
		} catch {
			if #available(iOS 16, macOS 14, tvOS 16, watchOS 9, *) {
				print("Failed to write [\(String(describing: Element.self)) to \(cacheURL.path(percentEncoded: false)): \(error.localizedDescription)")
			} else {
				print("Failed to write [\(String(describing: Element.self)) to \(cacheURL): \(error.localizedDescription)")
			}
		}
	}
	
	public var values: [Element] { cache }
	public var snapshot: [Element] { cache }
	public var isEmpty: Bool { cache.isEmpty }
	public var count: Int { cache.count }
	
	public mutating func removeAll() {
		guard !cache.isEmpty else { return }
		cache.removeAll()
		save()
	}
	
	mutating public func append(_ array: [Element]) {
		cache += array
	}
	
	mutating public func append(_ element: Element) {
		cache.append(element)
	}
	
	mutating public func replace(with new: [Element]) {
		cache = new
		save()
	}
}

public extension DiskBackedArray {
	func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
		try cache.filter(isIncluded)
	}
	
	mutating func remove(at index: Int) {
		cache.remove(at: index)
	}
	
	func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
		try cache.first(where: predicate)
	}
	
	mutating func remove(where matching: (Element) -> Bool) {
		cache = cache.filter { !matching($0) }
	}
}

extension DiskBackedArray: Equatable where Element: Equatable {
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.cache == rhs.cache
	}
}

public extension DiskBackedArray where Element: Equatable {
	func contains(_ element: Element) -> Bool {
		cache.contains(element)
	}
	
	mutating func insert(_ element: Element) {
		if uniqueElements, let index = cache.firstIndex(of: element) {
			self[index] = element
		} else {
			cache.append(element)
		}
	}
	
	subscript(_ index: Int) -> Element {
		get { cache[index] }
		set {
			if cache[index] == newValue { return }
			cache[index] = newValue
			save()
		}
	}
	
	mutating func append(_ array: [Element]) {
		if uniqueElements {
			for element in array {
				if !contains(element) {
					cache.append(element)
				}
			}
		} else {
			cache += array
		}
		save()
	}
	
	
	mutating func append(_ element: Element) {
		if !uniqueElements || !contains(element) { cache.append(element) }
	}
}
