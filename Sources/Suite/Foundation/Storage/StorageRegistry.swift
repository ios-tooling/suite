//
//  StorageRegistry.swift
//  Suite
//
//  Created by Ben Gottlieb on 7/7/26.
//

import Foundation
#if canImport(Synchronization)
	import Synchronization
#endif

/// Storage that holds a signed-in user's data and must be wiped when they
/// sign out.
public protocol SweepableStorage: AnyObject, Sendable {
	func clearForSignOut()
}

#if canImport(Synchronization)
/// Tracks every live `Outbox` and `Journal` so a host app can wipe them all
/// on sign-out. Instances register themselves at init.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum StorageRegistry {
	static let boxes = Mutex<[WeakStorageBox]>([])
	static let errorHandler = Mutex<(@Sendable (Error, String) -> Void)?>(nil)

	public static func register(_ storage: some SweepableStorage) {
		boxes.withLock { list in
			list.removeAll { $0.storage == nil }
			list.append(.init(storage: storage))
		}
	}

	public static func clearAllRegistered() {
		let current = boxes.withLock { list in
			list.removeAll { $0.storage == nil }
			return list
		}
		for box in current { box.storage?.clearForSignOut() }
	}

	/// Called when an outbox/journal fails to read or write its file. Set once
	/// at app startup to route errors to your reporting system.
	public static func setErrorHandler(_ handler: (@Sendable (Error, String) -> Void)?) {
		errorHandler.withLock { $0 = handler }
	}

	static func report(error: Error, context: String) {
		if let handler = errorHandler.withLock({ $0 }) {
			handler(error, context)
		} else {
			logg(error: error, context)
		}
	}

	struct WeakStorageBox: Sendable {
		weak var storage: (any SweepableStorage)?
	}
}
#endif
