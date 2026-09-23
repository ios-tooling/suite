//
//  DiskBackedDictionary+Loading.swift
//  Suite
//
//  Created by Ben Gottlieb on 8/31/26.
//

import Foundation

public extension DiskBackedDictionary where Key: Sendable, Value: Sendable {
	/// Builds a dictionary whose backing file is read and decoded off the calling
	/// thread. `init(cacheURL:)` does both inline, so constructing one on the main
	/// actor blocks it for a file read plus a JSON decode.
	static func loading(from cacheURL: URL, encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) async -> Self {
		// Only the detached task touches the decoder, and only until it returns.
		let decoder = decoder

		let cache = await Task.detached(priority: .utility) { () -> [Key: Value] in
			try? FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
			guard let data = try? Data(contentsOf: cacheURL) else { return [:] }
			return (try? decoder.decode([Key: Value].self, from: data)) ?? [:]
		}.value

		return .init(cacheURL: cacheURL, encoder: encoder, decoder: decoder, cache: cache, loadsFromDisk: false)
	}
}
