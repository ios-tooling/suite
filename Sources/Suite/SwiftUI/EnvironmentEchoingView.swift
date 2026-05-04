//
//  EnvironmentEchoingView.swift
//  Suite
//
//  Created by Ben Gottlieb on 12/20/25.
//

import SwiftUI

extension EnvironmentValues {
	@Entry public var echoedValues: EnvironmentValues?
}

/// Captures the current `EnvironmentValues` and republishes them via the `\.echoedValues` environment key,
/// so a sibling subtree can read the *parent's* environment as a snapshot. Useful for hosting controllers
/// or representable bridges that need access to the calling context's environment.
@available(iOS 15, macOS 12, visionOS 1, watchOS 10, *)
public struct EnvironmentEchoingView<Content: View>: View {
	let content: () -> Content

	@Environment(\.self) var echoedValues

	public init(content: @escaping () -> Content) {
		self.content = content
	}

	public var body: some View {
		content()
			.environment(\.echoedValues, echoedValues)
	}
}
