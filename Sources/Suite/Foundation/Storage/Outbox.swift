//
//  Outbox.swift
//  Suite
//
//  Created by Ben Gottlieb on 7/7/26.
//

import Foundation
#if canImport(Synchronization)
	import Synchronization

/// A pending-upload queue persisted to a single JSON file. Unlike a cache,
/// its contents are irreplaceable until uploaded — there is no eviction, and
/// the file lives in a non-purgeable location by default.
///
/// Appends are synchronous and safe from any isolation. Disk writes happen
/// under the lock, coalesced via `saveEvery`; call `flush()` before the app
/// backgrounds if you coalesce.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public final class Outbox<Element: Codable & Sendable>: Sendable, SweepableStorage {
	let fileURL: URL
	let cap: Int?
	let saveEvery: Int
	let codec: StorageDateCodec
	let state: Mutex<State>

	struct State {
		var items: [Element] = []
		var unsavedCount = 0
	}

	/// - Parameters:
	///   - cap: oldest items are dropped once the count exceeds this.
	///   - saveEvery: write to disk every N mutations (1 = write-through).
	///   - codec: must match the site's historical on-disk date format.
	public init(name: String, location: StorageLocation = .library, cap: Int? = nil, saveEvery: Int = 1, codec: StorageDateCodec = .iso8601) {
		self.fileURL = location.url(forFile: name)
		self.cap = cap
		self.saveEvery = max(saveEvery, 1)
		self.codec = codec

		var initial = State()
		if let data = try? Data(contentsOf: fileURL) {
			do {
				initial.items = try codec.decoder.decode([Element].self, from: data)
			} catch {
				StorageRegistry.report(error: error, context: "Failed to load outbox \(name)")
			}
		}
		state = Mutex(initial)
		StorageRegistry.register(self)
	}

	public var pending: [Element] { state.withLock { $0.items } }
	public var count: Int { state.withLock { $0.items.count } }
	public var isEmpty: Bool { state.withLock { $0.items.isEmpty } }

	public func append(_ element: Element) {
		state.withLock { current in
			current.items.append(element)
			if let cap, current.items.count > cap { current.items.removeFirst(current.items.count - cap) }
			noteMutation(&current)
		}
	}

	/// Replaces the first element matching `predicate`, or appends if none does.
	public func upsert(_ element: Element, matching predicate: (Element) -> Bool) {
		state.withLock { current in
			if let index = current.items.firstIndex(where: predicate) {
				current.items[index] = element
			} else {
				current.items.append(element)
			}
			noteMutation(&current)
		}
	}

	public func remove(where predicate: (Element) -> Bool) {
		state.withLock { current in
			current.items.removeAll(where: predicate)
			noteMutation(&current)
		}
	}

	/// Replaces the entire contents — for owners that mutate a working copy
	/// and persist it wholesale.
	public func replace(with items: [Element]) {
		state.withLock { current in
			current.items = items
			if let cap, current.items.count > cap { current.items.removeFirst(current.items.count - cap) }
			noteMutation(&current)
		}
	}

	/// Removes the first `count` items — the ones included in an upload snapshot —
	/// preserving anything appended since the snapshot was taken.
	public func removeFirst(_ count: Int) {
		state.withLock { current in
			current.items.removeFirst(min(count, current.items.count))
			noteMutation(&current)
		}
	}

	public func clear() {
		state.withLock { current in
			current.items = []
			save(&current)
		}
	}

	public func flush() {
		state.withLock { current in
			if current.unsavedCount > 0 { save(&current) }
		}
	}

	public func clearForSignOut() { clear() }

	private func noteMutation(_ current: inout State) {
		current.unsavedCount += 1
		if current.unsavedCount >= saveEvery { save(&current) }
	}

	private func save(_ current: inout State) {
		do {
			try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
			let data = try codec.encoder.encode(current.items)
			try data.write(to: fileURL, options: .atomic)
			current.unsavedCount = 0
		} catch {
			StorageRegistry.report(error: error, context: "Failed to save outbox \(fileURL.lastPathComponent)")
		}
	}
}
#endif
