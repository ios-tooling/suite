//
//  AppLifecycleMonitor.swift
//  Suite
//
//  Created by Ben Gottlieb on 6/15/26.
//

import Foundation

/// Runs registered code at system-defined lifecycle events (``AppLifecycleEvent``).
///
/// Register a handler for one or more events and keep the returned ``Registration``
/// if you need to stop observing later:
///
/// ```swift
/// AppLifecycleMonitor.instance.when(.resume) {
///     try await MyStore.instance.refresh()
/// }
/// ```
///
/// Both synchronous and `async throws` handlers are supported. Synchronous handlers
/// run on the thread that posts the notification (the main thread for every
/// app-lifecycle event) — use one when a handler must finish before the app suspends
/// or terminates. `async` handlers run in a detached `Task`; any error they throw is
/// reported via `logg(error:)`.
@MainActor public final class AppLifecycleMonitor {
	public static let instance = AppLifecycleMonitor()

	public typealias Handler = @Sendable () -> Void
	public typealias ThrowingHandler = @Sendable () async throws -> Void

	/// A token representing a single `when`/`register` call. Call ``cancel()`` to stop observing.
	@MainActor public final class Registration {
		fileprivate var tokens: [any NSObjectProtocol] = []
		fileprivate weak var monitor: AppLifecycleMonitor?

		public func cancel() { monitor?.cancel(self) }
	}

	private var registrations: [Registration] = []

	private init() { }

	/// Run `handler` synchronously whenever any of the given lifecycle events occurs.
	@discardableResult public func when(_ events: AppLifecycleEvent, perform handler: @escaping Handler) -> Registration {
		observe(events, perform: handler)
	}

	/// Run an async `handler` whenever any of the given lifecycle events occurs, reporting any thrown error.
	@discardableResult public func when(_ events: AppLifecycleEvent, perform handler: @escaping ThrowingHandler) -> Registration {
		observe(events) {
			Task {
				do { try await handler() }
				catch { logg(error: error, "AppLifecycleMonitor handler threw") }
			}
		}
	}

	private func observe(_ events: AppLifecycleEvent, perform handler: @escaping Handler) -> Registration {
		let registration = Registration()
		registration.monitor = self
		for name in events.notificationNames {
			let token = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { _ in
				handler()
			}
			registration.tokens.append(token)
		}
		registrations.append(registration)
		// `.launch` has no notification to observe — the app has already launched by the
		// time we can register — so run the handler now.
		if events.contains(.launch) { handler() }
		return registration
	}

	/// Stop running the handler associated with `registration`.
	public func cancel(_ registration: Registration) {
		for token in registration.tokens { NotificationCenter.default.removeObserver(token) }
		registration.tokens.removeAll()
		registrations.removeAll { $0 === registration }
	}
}
