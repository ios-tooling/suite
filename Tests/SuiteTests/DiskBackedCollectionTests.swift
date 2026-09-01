//
//  DiskBackedCollectionTests.swift
//  Suite
//
//  Created by Ben Gottlieb on 8/31/26.
//

import Testing
import Foundation
import Suite

struct DiskBackedCollectionTests {
	private func temporaryURL() -> URL {
		FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
	}

	/// The whole point of the coalescing writer: a mutation shouldn't cost an
	/// atomic rewrite of the entire file. Callers that need the file current say so.
	@Test func mutationsDontWriteImmediately() throws {
		let url = temporaryURL()
		defer { try? FileManager.default.removeItem(at: url) }

		var dictionary = DiskBackedDictionary<String, Int>(cacheURL: url)
		dictionary["first"] = 1
		dictionary["second"] = 2
		#expect(!FileManager.default.fileExists(atPath: url.path))

		dictionary.flushToDisk()
		#expect(FileManager.default.fileExists(atPath: url.path))
	}

	@Test func loadingReadsWhatWasWritten() async throws {
		let url = temporaryURL()
		defer { try? FileManager.default.removeItem(at: url) }

		var dictionary = DiskBackedDictionary<String, Int>(cacheURL: url)
		dictionary["first"] = 1
		dictionary.flushToDisk()

		let loaded = await DiskBackedDictionary<String, Int>.loading(from: url)
		#expect(loaded["first"] == 1)
		#expect(loaded.count == 1)
	}

	/// A missing file is an empty collection, not a failure.
	@Test func loadingAMissingFileIsEmpty() async throws {
		let loaded = await DiskBackedDictionary<String, Int>.loading(from: temporaryURL())
		#expect(loaded.isEmpty)
	}

	@Test func arrayLoadingReadsWhatWasWritten() async throws {
		let url = temporaryURL()
		defer { try? FileManager.default.removeItem(at: url) }

		var array = DiskBackedArray<Int>(cacheURL: url)
		array.append(1)
		array.append(2)
		#expect(!FileManager.default.fileExists(atPath: url.path))

		array.flushToDisk()

		let loaded = await DiskBackedArray<Int>.loading(from: url)
		#expect(loaded.values == [1, 2])
	}
}
