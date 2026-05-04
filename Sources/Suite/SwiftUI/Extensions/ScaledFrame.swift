//
//  ScaledFrame.swift
//  Suite
//
//  Created by Claude Code
//

import SwiftUI

public extension View {
	/// Like `.frame(width:height:)`, but the dimensions scale with Dynamic Type
	/// (relative to `.body`) on iOS 14+/macOS 11+/watchOS 7+/tvOS 14+.
	/// On older OS versions the dimensions are applied unscaled.
	func scaledFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
		modifier(ScaledFrameModifier(width: width, height: height))
	}
}

private struct ScaledFrameModifier: ViewModifier {
	let width: CGFloat?
	let height: CGFloat?

	func body(content: Content) -> some View {
		if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
			content.modifier(ScaledFrameImpl(width: width, height: height))
		} else {
			content.frame(width: width, height: height)
		}
	}
}

@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
private struct ScaledFrameImpl: ViewModifier {
	@ScaledMetric private var scaledWidth: CGFloat
	@ScaledMetric private var scaledHeight: CGFloat
	private let hasWidth: Bool
	private let hasHeight: Bool

	init(width: CGFloat?, height: CGFloat?) {
		self._scaledWidth = ScaledMetric(wrappedValue: width ?? 0)
		self._scaledHeight = ScaledMetric(wrappedValue: height ?? 0)
		self.hasWidth = width != nil
		self.hasHeight = height != nil
	}

	func body(content: Content) -> some View {
		content.frame(
			width: hasWidth ? scaledWidth : nil,
			height: hasHeight ? scaledHeight : nil
		)
	}
}
