//
//  DiskBackedArray+Loading.swift
//  Suite
//
//  Created by Ben Gottlieb on 8/31/26.
//

import Foundation

public extension DiskBackedArray where Element: Sendable {
	/// Builds an array whose backing file is read and decoded off the calling
	/// thread. `init(cacheURL:)` does both inline, so constructing one on the main
	/// actor blocks it for a file read plus a JSON decode.
	static func loading(from cacheURL: URL, debug: Bool = false, encoder: JSONEncoder? = nil, decoder: JSONDecoder? = nil, uniqueElements: Bool = true) async -> Self {
		let loader = decoder ?? Self.defaultDecoder(debug: debug)
		// Only the detached task touches the decoder, and only until it returns.
		let unsafeLoader = loader

		let cache = await Task.detached(priority: .utility) { () -> [Element] in
			try? FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
			guard let data = try? Data(contentsOf: cacheURL) else { return [] }
			return (try? unsafeLoader.decode([Element].self, from: data)) ?? []
		}.value

		return .init(debug: debug, cacheURL: cacheURL, encoder: encoder, decoder: loader, cache: cache, uniqueElements: uniqueElements, loadsFromDisk: false)
	}
}
