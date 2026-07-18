//
//  iOS14Shims.swift
//
//
//  Created by Ben Gottlieb on 8/26/23.
//

import SwiftUI

@available(OSX 12, iOS 13.0, watchOS 8.0, tvOS 14, *)
public extension View {
	func monospacedDigit14() -> some View {
		if #available(iOS 15.0, tvOS 15, *) {
			return AnyView(monospacedDigit())
		}
		return AnyView(self)
	}

	func alignedOverlay<Content: View>(_ alignment: Alignment, content: @escaping () -> Content) -> some View {
		if #available(iOS 15.0, tvOS 15, *) {
			return AnyView(overlay(alignment: alignment, content: content))
		}
		return AnyView(overlay(
			HStack {
				if alignment == .trailing || alignment == .topTrailing || alignment == .bottomTrailing { Spacer() }
				VStack {
					if alignment == .bottom || alignment == .bottomTrailing || alignment == .bottomLeading { Spacer() }

					content()

					if alignment == .top || alignment == .topTrailing || alignment == .topLeading { Spacer() }
				}
				if alignment == .leading || alignment == .topLeading || alignment == .bottomLeading { Spacer() }
			}
		))
	}
}
