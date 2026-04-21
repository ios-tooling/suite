//
//  NotYetImplemented.swift
//  Suite
//
//  Flags UI that is visually present but whose action is a no-op or isn't
//  wired to a real backend yet. Useful while iterating on a design when
//  you want the layout in place but don't want to ship half-working
//  controls by accident.
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, watchOS 9.0, *)
public extension View {
	/// Marks this view as a **not-yet-implemented** placeholder by overlaying
	/// a dashed red border. The border is intentionally loud so placeholders
	/// are impossible to miss in design review. Pass `false` to disable the
	/// marker without removing the call site — handy when a feature just
	/// landed and you're about to delete the flag.
	func notYetImplemented(_ active: Bool = true) -> some View {
		modifier(NotYetImplementedModifier(active: active))
	}
}

@available(iOS 15.0, macOS 12.0, watchOS 9.0, *)
public struct NotYetImplementedModifier: ViewModifier {
	public var active: Bool

	public init(active: Bool = true) {
		self.active = active
	}

	public func body(content: Content) -> some View {
		if active {
			content
				.overlay(
					RoundedRectangle(cornerRadius: 4)
						.strokeBorder(
							Color.red.opacity(0.65),
							style: StrokeStyle(lineWidth: 1, dash: [3, 2])
						)
				)
		} else {
			content
		}
	}
}
