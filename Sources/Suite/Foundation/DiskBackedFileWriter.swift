//
//  DiskBackedFileWriter.swift
//  Suite
//
//  Created by Ben Gottlieb on 8/31/26.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Coalesces the disk writes for `DiskBackedDictionary` and `DiskBackedArray`.
///
/// Both types used to write the whole file, atomically and inline, on every
/// single mutation. Anything that records one change per row — a list that logs
/// an impression per cell, say — paid a full atomic write (temp file, write,
/// rename) per row, on whatever thread it was mutating from, which is usually
/// the main one.
///
/// Now a mutation just hands over the encoded bytes: the first one schedules a
/// write, everything before it lands replaces what will be written, and the
/// write itself happens off the caller's thread. Backgrounding and termination
/// write immediately, so nothing waits on the timer to become durable.
final class DiskBackedFileWriter: @unchecked Sendable {
	let url: URL
	let interval: TimeInterval

	private let lock = NSLock()
	private var pendingData: Data?
	private var isScheduled = false
	private var observers: [any NSObjectProtocol] = []

	init(url: URL, interval: TimeInterval = 2) {
		self.url = url
		self.interval = interval

		#if canImport(UIKit) && !os(watchOS)
		for name in [UIApplication.didEnterBackgroundNotification, UIApplication.willTerminateNotification] {
			let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [weak self] _ in
				self?.writePendingData()
			}
			observers.append(observer)
		}
		#endif
	}

	deinit {
		for observer in observers { NotificationCenter.default.removeObserver(observer) }
		writePendingData()
	}

	/// Queues `data` to be written, scheduling a write if one isn't already coming.
	func save(_ data: Data) {
		lock.lock()
		pendingData = data
		let needsScheduling = !isScheduled
		isScheduled = true
		lock.unlock()

		guard needsScheduling else { return }
		Task.detached(priority: .utility) { [weak self] in
			guard let self else { return }
			try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
			writePendingData()
		}
	}

	/// Writes anything outstanding right now, on the calling thread.
	func writePendingData() {
		lock.lock()
		let data = pendingData
		pendingData = nil
		isScheduled = false
		lock.unlock()

		guard let data else { return }
		do {
			try data.write(to: url, options: .atomic)
		} catch {
			if #available(iOS 16, macOS 14, tvOS 16, watchOS 9, *) {
				print("Failed to write to \(url.path(percentEncoded: false)): \(error.localizedDescription)")
			} else {
				print("Failed to write to \(url): \(error.localizedDescription)")
			}
		}
	}
}
