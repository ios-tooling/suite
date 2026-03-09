
//
//  ChangeTracker.swift
//  Suite
//

#if canImport(Observation) && canImport(SwiftUI)
import Observation
import SwiftUI

// MARK: - IDToken

@available(iOS 17, macOS 14, watchOS 10, tvOS 17, *)
extension ChangeTracker where ID == String {
	public static let instance = ChangeTracker()
}

@available(iOS 17, macOS 14, watchOS 10, tvOS 17, *)
@Observable final class IDToken {
	var version: Int = 0
}

// MARK: - ChangeTracker

/// Allows SwiftUI views to subscribe to invalidations for specific IDs.
/// Views register interest via `.observe(id, in: tracker)`.
/// Call `didChange(id:)` to rebuild only the views observing that ID.
@available(iOS 17, macOS 14, watchOS 10, tvOS 17, *)
@MainActor
public final class ChangeTracker<ID: Hashable> {
	private struct WeakToken {
		weak var value: IDToken?
	}

	private var tokens: [ID: WeakToken] = [:]

	public init() {}

	func token(for id: ID) -> IDToken {
		if let existing = tokens[id]?.value { return existing }
		let token = IDToken()
		tokens[id] = WeakToken(value: token)
		return token
	}

	public func didChange(id: ID) {
		tokens[id]?.value?.version += 1
	}
}

// MARK: - View Modifiers

@available(iOS 17, macOS 14, watchOS 10, tvOS 17, *)
private struct ObserveIDModifier<ID: Hashable>: ViewModifier {
	let id: ID
	let tracker: ChangeTracker<ID>
	@State private var token: IDToken?

	func body(content: Content) -> some View {
		let _ = token?.version
		content
			.onAppear { token = tracker.token(for: id) }
			.onDisappear { token = nil }
			.onChange(of: id) { _, newID in token = tracker.token(for: newID) }
	}
}

@available(iOS 17, macOS 14, watchOS 10, tvOS 17, *)
private struct OnTrackedChangeModifier<ID: Hashable>: ViewModifier {
	let id: ID
	let tracker: ChangeTracker<ID>
	let callback: () -> Void
	@State private var token: IDToken?

	func body(content: Content) -> some View {
		content
			.onAppear { token = tracker.token(for: id) }
			.onDisappear { token = nil }
			.onChange(of: id) { _, newID in token = tracker.token(for: newID) }
			.onChange(of: token?.version) { _, _ in callback() }
	}
}

// MARK: - View Extensions

@available(iOS 17, macOS 14, watchOS 10, tvOS 17, *)
public extension View {
	/// Registers this view as an observer for `id` in the given `ChangeTracker`.
	/// The view will be rebuilt whenever `tracker.didChange(id:)` is called with this ID.
	@MainActor func observe<ID: Hashable>(_ id: ID, in tracker: ChangeTracker<ID>) -> some View {
		modifier(ObserveIDModifier(id: id, tracker: tracker))
	}

	@MainActor func observe(_ id: String) -> some View {
		modifier(ObserveIDModifier(id: id, tracker: .instance))
	}

	/// Calls `callback` whenever `tracker.didChange(id:)` is invoked for the given ID.
	@MainActor func onTrackedChange<ID: Hashable>(_ id: ID, in tracker: ChangeTracker<ID>, callback: @escaping () -> Void) -> some View {
		modifier(OnTrackedChangeModifier(id: id, tracker: tracker, callback: callback))
	}

	@MainActor func onTrackedChange(_ id: String, callback: @escaping () -> Void) -> some View {
		modifier(OnTrackedChangeModifier(id: id, tracker: .instance, callback: callback))
	}
}
#endif
