//
//  OutboxJournalTests.swift
//  Suite
//
//  Created by Ben Gottlieb on 7/7/26.
//

import Testing
import Foundation
@testable import Suite

private struct Entry: Codable, Sendable, Equatable {
	var id: Int
	var date: Date
}

private func tempFile() -> StorageLocation {
	.custom(URL.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json"))
}

private func tempDirectory() -> StorageLocation {
	.custom(URL.temporaryDirectory.appendingPathComponent(UUID().uuidString))
}

@Suite("Outbox")
struct OutboxTests {
	@Test("Appends persist and reload across instances")
	func persistence() {
		guard #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let location = tempFile()
		let outbox = Outbox<Entry>(name: "test", location: location)
		outbox.append(Entry(id: 1, date: .now))
		outbox.append(Entry(id: 2, date: .now))

		let reloaded = Outbox<Entry>(name: "test", location: location)
		#expect(reloaded.pending.map(\.id) == [1, 2])
	}

	@Test("Cap drops oldest items")
	func capDropsOldest() {
		guard #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let outbox = Outbox<Entry>(name: "test", location: tempFile(), cap: 3)
		for id in 1...5 { outbox.append(Entry(id: id, date: .now)) }
		#expect(outbox.pending.map(\.id) == [3, 4, 5])
	}

	@Test("removeFirst preserves items appended after a snapshot")
	func pruneAfterUpload() {
		guard #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let outbox = Outbox<Entry>(name: "test", location: tempFile())
		for id in 1...3 { outbox.append(Entry(id: id, date: .now)) }
		let snapshot = outbox.pending
		outbox.append(Entry(id: 4, date: .now))

		outbox.removeFirst(snapshot.count)
		#expect(outbox.pending.map(\.id) == [4])
	}

	@Test("upsert replaces a matching element")
	func upsertReplaces() {
		guard #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let outbox = Outbox<Entry>(name: "test", location: tempFile())
		outbox.append(Entry(id: 1, date: .distantPast))
		outbox.upsert(Entry(id: 1, date: .now), matching: { $0.id == 1 })
		outbox.upsert(Entry(id: 2, date: .now), matching: { $0.id == 2 })

		#expect(outbox.count == 2)
		#expect(outbox.pending.first?.date != .distantPast)
	}

	@Test("saveEvery coalesces writes until flush")
	func coalescedWrites() {
		guard #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let location = tempFile()
		let outbox = Outbox<Entry>(name: "test", location: location, saveEvery: 10)
		outbox.append(Entry(id: 1, date: .now))

		#expect(Outbox<Entry>(name: "test", location: location).isEmpty)
		outbox.flush()
		#expect(Outbox<Entry>(name: "test", location: location).count == 1)
	}

	@Test("deferredToDate codec reads legacy files")
	func legacyCodec() throws {
		guard #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let location = tempFile()
		let legacy = [Entry(id: 9, date: .now)]
		try JSONEncoder().encode(legacy).write(to: location.url(forFile: "test"))

		let outbox = Outbox<Entry>(name: "test", location: location, codec: .deferredToDate)
		#expect(outbox.pending.map(\.id) == [9])
	}

	@Test("Concurrent appends are all recorded")
	func concurrentAppends() async {
		guard #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let outbox = Outbox<Entry>(name: "test", location: tempFile(), saveEvery: 100)
		await withTaskGroup(of: Void.self) { group in
			for id in 1...50 {
				group.addTask { outbox.append(Entry(id: id, date: .now)) }
			}
		}
		#expect(outbox.count == 50)
	}

	@Test("Sweep clears outboxes")
	func sweep() {
		guard #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let outbox = Outbox<Entry>(name: "test", location: tempFile())
		outbox.append(Entry(id: 1, date: .now))
		StorageRegistry.clearAllRegistered()
		#expect(outbox.isEmpty)
	}
}

@Suite("Journal")
struct JournalTests {
	@Test("Appends land in per-day files and reload")
	func dayPartitioning() {
		guard #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let location = tempDirectory()
		let journal = Journal<Entry>(name: "test", location: location)
		let yesterday = Date(timeIntervalSinceNow: -24 * 60 * 60)

		journal.append(Entry(id: 1, date: yesterday), at: yesterday)
		journal.append(Entry(id: 2, date: .now), at: .now)

		#expect(journal.days.count == 2)
		#expect(journal.entries(on: Date.Day(Date())).map(\.id) == [2])
		#expect(journal.entries(on: Date.Day(yesterday)).map(\.id) == [1])
	}

	@Test("Rewrite replaces a day's entries")
	func rewrite() {
		guard #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let location = tempDirectory()
		let journal = Journal<Entry>(name: "test", location: location)
		journal.append(Entry(id: 1, date: .now))

		let today = Date.Day(Date())
		journal.rewrite(day: today, entries: [Entry(id: 99, date: .now)])
		#expect(journal.entries(on: today).map(\.id) == [99])

		let reloaded = Journal<Entry>(name: "test", location: location)
		#expect(reloaded.entries(on: today).map(\.id) == [99])
	}

	@Test("Retention prunes old day files")
	func retention() throws {
		guard #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let location = tempDirectory()
		let journal = Journal<Entry>(name: "test", location: location)
		let oldDay = Date.Day(Date(timeIntervalSinceNow: -40 * 24 * 60 * 60))
		journal.rewrite(day: oldDay, entries: [Entry(id: 1, date: .now)])

		let pruned = Journal<Entry>(name: "test", location: location, retentionDays: 30)
		#expect(!pruned.days.contains(oldDay))
	}

	@Test("Reads files written in LocationHistory's legacy layout")
	func legacyLayout() throws {
		guard #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let directory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
		let day = Date.Day(Date())
		let legacy = [Entry(id: 7, date: .now)]
		try JSONEncoder().encode(legacy).write(to: directory.appendingPathComponent(day.ymdString("-") + ".json"))

		let journal = Journal<Entry>(name: "test", location: .custom(directory), codec: .deferredToDate)
		#expect(journal.entries(on: day).map(\.id) == [7])
	}

	@Test("Sweep clears journals")
	func sweep() {
		guard #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let journal = Journal<Entry>(name: "test", location: tempDirectory())
		journal.append(Entry(id: 1, date: .now))
		StorageRegistry.clearAllRegistered()
		#expect(journal.days.isEmpty)
	}
}
