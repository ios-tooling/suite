//
//  Journal.swift
//  Suite
//
//  Created by Ben Gottlieb on 7/7/26.
//

import Foundation
#if canImport(Synchronization)
	import Synchronization

/// A day-partitioned local archive: one JSON file per calendar day
/// (`2026-7-7.json`), with optional retention pruning. Unlike a cache its
/// contents are irreplaceable; unlike an outbox nothing is pending — days are
/// kept, queried, and rewritten in place.
///
/// Appends go to the day of the entry's date, rolling files over at midnight.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public final class Journal<Element: Codable & Sendable>: Sendable, SweepableStorage {
	let directory: URL
	let retentionDays: Int?
	let saveEvery: Int
	let codec: StorageDateCodec
	let state: Mutex<State>

	struct State {
		var currentDay: Date.Day
		var entries: [Element] = []
		var unsavedCount = 0
	}

	public init(name: String, location: StorageLocation = .documents, retentionDays: Int? = nil, saveEvery: Int = 1, codec: StorageDateCodec = .iso8601) {
		self.directory = location.directory(named: name)
		self.retentionDays = retentionDays
		self.saveEvery = max(saveEvery, 1)
		self.codec = codec

		try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
		let today = Date.Day(Date())
		state = Mutex(State(currentDay: today, entries: Self.load(day: today, in: directory, codec: codec)))

		applyRetention()
		StorageRegistry.register(self)
	}

	public func append(_ element: Element, at date: Date = Date()) {
		let day = Date.Day(date)
		state.withLock { current in
			if day != current.currentDay {
				if current.unsavedCount > 0 { save(&current) }
				current.currentDay = day
				current.entries = Self.load(day: day, in: directory, codec: codec)
			}
			current.entries.append(element)
			current.unsavedCount += 1
			if current.unsavedCount >= saveEvery { save(&current) }
		}
	}

	/// Every day with a stored file, oldest first.
	public var days: [Date.Day] {
		let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
		return files.compactMap { Date.Day(ymd: $0.deletingPathExtension().lastPathComponent) }.sorted()
	}

	public func entries(on day: Date.Day) -> [Element] {
		state.withLock { current in
			if day == current.currentDay { return current.entries }
			return Self.load(day: day, in: directory, codec: codec)
		}
	}

	public func rewrite(day: Date.Day, entries: [Element]) {
		state.withLock { current in
			if day == current.currentDay {
				current.entries = entries
				save(&current)
			} else {
				write(entries, to: url(for: day))
			}
		}
	}

	public func flush() {
		state.withLock { current in
			if current.unsavedCount > 0 { save(&current) }
		}
	}

	/// Deletes day files older than `retentionDays`. Runs automatically at init.
	public func applyRetention() {
		guard let retentionDays else { return }
		let limit = Date.Day(Date(timeIntervalSinceNow: -Double(retentionDays) * 24 * 60 * 60))
		for day in days where day < limit {
			try? FileManager.default.removeItem(at: url(for: day))
		}
	}

	public func clear() {
		state.withLock { current in
			try? FileManager.default.removeItem(at: directory)
			try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
			current.entries = []
			current.unsavedCount = 0
		}
	}

	public func clearForSignOut() { clear() }

	func url(for day: Date.Day) -> URL {
		directory.appendingPathComponent(day.ymdString("-") + ".json")
	}

	static func load(day: Date.Day, in directory: URL, codec: StorageDateCodec) -> [Element] {
		let url = directory.appendingPathComponent(day.ymdString("-") + ".json")
		guard let data = try? Data(contentsOf: url) else { return [] }
		do {
			return try codec.decoder.decode([Element].self, from: data)
		} catch {
			StorageRegistry.report(error: error, context: "Failed to load journal day \(day.ymdString("-"))")
			return []
		}
	}

	private func save(_ current: inout State) {
		write(current.entries, to: url(for: current.currentDay))
		current.unsavedCount = 0
	}

	private func write(_ entries: [Element], to url: URL) {
		do {
			let data = try codec.encoder.encode(entries)
			try data.write(to: url, options: .atomic)
		} catch {
			StorageRegistry.report(error: error, context: "Failed to save journal day \(url.lastPathComponent)")
		}
	}
}
#endif
