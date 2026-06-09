//
//  DeferredSave.swift
//  Suite
//

import Foundation
import SwiftData

/// Mixin protocol for actors that own a `ModelContext` and want throttled saves.
/// Call `deferSave()` on any mutation; a real save fires only after `delay` seconds of quiet.
@available(iOS 17, macOS 14, watchOS 10, tvOS 17, *)
public protocol DeferredSavable: Actor {
	var deferredSaveTask: Task<Void, Never>? { get set }
	/// The `ModelContext` to save. Must be main-actor-isolated.
	@MainActor var mainContext: ModelContext! { get }
}

@available(iOS 17, macOS 14, watchOS 10, tvOS 17, *)
public extension DeferredSavable {
	/// Cancels any pending save and schedules a new one after `delay` seconds.
	func deferSave(delay: TimeInterval = 2.0) {
		deferredSaveTask?.cancel()
		deferredSaveTask = Task { @MainActor in
			guard !Task.isCancelled else { return }
			try? await Task.sleep(for: .seconds(delay))
			guard !Task.isCancelled else { return }
			try? mainContext.save()
		}
	}
}
