//
//  Outlined.swift
//  Suite
//
//  Created by Ben Gottlieb on 1/5/25.
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, watchOS 9.0, *)
public extension View {
	func outlined(in color: Color, width: CGFloat = 0.5) -> some View {
		modifier(OutlinedModifier(size: width, color: color))
	}
}

@available(iOS 15.0, macOS 12.0, watchOS 9.0, *)
struct OutlinedModifier: ViewModifier {
	private let id = UUID()
	var size = 1.0
	var color = Color.blue
	
	func body(content: Content) -> some View {
		if size > 0 {
			appliedBackground(content: content)
		} else {
			content
		}
	}
	
	private func appliedBackground(content: Content) -> some View {
		content
			.padding(size * 2)
			.background(
				Rectangle()
					.foregroundColor(color)
					.mask(alignment: .center) {
						mask(content: content)
					}
			)
	}
	
	func mask(content: Content) -> some View {
		Canvas { context, size in
			context.addFilter(.alphaThreshold(min: 0.01))
			if let resolvedView = context.resolveSymbol(id: id) {
				context.draw(resolvedView, at: .init(x: size.width/2, y: size.height/2))
			}
		} symbols: {
			content
				.tag(id)
				.blur(radius: size)
		}
	}
}
