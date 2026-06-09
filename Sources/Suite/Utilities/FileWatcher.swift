//
//  FileWatcher.swift
//  Suite
//

import Foundation

/// Watches a file or directory for filesystem changes (write, rename, delete).
/// Retain the instance for as long as you want to receive callbacks; releasing it cancels the watch.
public final class FileWatcher: Sendable {
	private let source: DispatchSourceFileSystemObject
	private let fileDescriptor: Int32

	/// Returns nil if the path cannot be opened (e.g. file does not exist yet).
	public init?(url: URL, queue: DispatchQueue = .main, onChange: @escaping @Sendable () -> Void) {
		let fd = open(url.path, O_EVTONLY)
		guard fd >= 0 else { return nil }
		self.fileDescriptor = fd

		let source = DispatchSource.makeFileSystemObjectSource(
			fileDescriptor: fd,
			eventMask: [.write, .rename, .delete],
			queue: queue
		)
		source.setEventHandler { onChange() }
		source.setCancelHandler { close(fd) }
		source.resume()
		self.source = source
	}

	/// Watches a parent directory and reports whether a specific child file exists whenever the directory changes.
	public convenience init?(watchingExistenceOf url: URL, queue: DispatchQueue = .main, fileExists: @escaping @Sendable (Bool) -> Void) {
		self.init(url: url.deletingLastPathComponent(), queue: queue) {
			fileExists(FileManager.default.fileExists(atPath: url.path))
		}
		fileExists(FileManager.default.fileExists(atPath: url.path))
	}

	deinit {
		source.cancel()
	}
}
