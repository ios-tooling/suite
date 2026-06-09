//
//  Haptics.swift
//  Suite
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Lightweight haptic feedback manager. Call `warmup()` before a known interaction
/// to reduce latency, then `smallBump()` / `largeBump()` at the moment of contact.
@available(iOS 17, macOS 14, watchOS 10, tvOS 17, *)
@MainActor @Observable public final class Haptics {
	public static let instance = Haptics()

	#if os(iOS)
		private let large = UIImpactFeedbackGenerator(style: .medium)
		private let small = UIImpactFeedbackGenerator(style: .soft)

		public func smallBump() { small.impactOccurred() }
		public func largeBump() { large.impactOccurred() }

		public func warmup() {
			large.prepare()
			small.prepare()
		}

		public func playClick() { small.impactOccurred(intensity: 1.0) }
	#else
		public func smallBump() {}
		public func largeBump() {}
		public func warmup() {}
		public func playClick() {}
	#endif
}
