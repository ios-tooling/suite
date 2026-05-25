//
//  View+SizeReporting.swift
//
//
//  Created by ben on 4/5/20.
//

#if canImport(SwiftUI)
#if canImport(Combine)

import SwiftUI

@available(iOS 17.0, macOS 14, tvOS 17, watchOS 10, *)
public struct SizeViewModifier: ViewModifier {
	@Binding var size: CGSize

	public func body(content: Content) -> some View {
		content.onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
	}
}

@available(iOS 17.0, macOS 14, tvOS 17, watchOS 10, *)
public extension View {
	func sizeReporting(_ size: Binding<CGSize>) -> some View {
		onGeometryChange(for: CGSize.self, of: \.size) { size.wrappedValue = $0 }
	}

	func frameReporting(_ frame: Binding<CGRect>, in space: CoordinateSpace = .global, firstTimeOnly: Bool = false) -> some View {
		onGeometryChange(for: CGRect.self, of: { $0.frame(in: space) }) { newRect in
			if (!firstTimeOnly || frame.wrappedValue == .zero) && frame.wrappedValue != newRect {
				frame.wrappedValue = newRect
			}
		}
	}

	func frameReporting<Key: Hashable & Sendable>(_ frames: Binding<[Key: CGRect]>, key: Key, in space: CoordinateSpace = .global, firstTimeOnly: Bool = false) -> some View {
		onGeometryChange(for: CGRect.self, of: { $0.frame(in: space) }) { newRect in
			if (!firstTimeOnly || frames[key].wrappedValue == nil) && frames.wrappedValue[key] != newRect {
				frames.wrappedValue[key] = newRect
			}
		}
	}

	func reportGeometry(frame: Binding<CGRect?>? = nil, size: Binding<CGSize?>? = nil, in space: CoordinateSpace = .global) -> some View {
		onGeometryChange(for: CGRect.self, of: { $0.frame(in: space) }) { newFrame in
			frame?.wrappedValue = newFrame
			size?.wrappedValue = newFrame.size
		}
	}

	func sizeReporting(_ callback: @escaping (CGSize) -> Void) -> some View {
		onGeometryChange(for: CGSize.self, of: \.size) { callback($0) }
	}

	func sizeLogging(_ logString: String) -> some View {
		onGeometryChange(for: CGSize.self, of: \.size) { logg("\(logString): \($0)") }
	}
}

@available(iOS 17.0, macOS 14, tvOS 17, watchOS 10, *)
public extension View {
	func sizeDisplaying(text: Color = .white, fill: Color = .red) -> some View {
		self.overlay(SizeOverlay(dimensionsTextColor: text, dimensionsColor: fill))
	}

	func positionDisplaying(text: Color = .white, fill: Color = .red) -> some View {
		self.overlay(PositionOverlay(dimensionsTextColor: text, dimensionsColor: fill))
	}
}

@available(iOS 17.0, macOS 14, tvOS 17, watchOS 10, *)
struct SizeOverlay: View {
	@State var size: CGSize?

	var dimensionsTextColor = Color.white
	var dimensionsColor = Color.red
	var dimensionThickness = 1.0

	var aspectRatioString: String {
		guard let size else { return "" }
		return String(format: "%.2f", size.width / size.height)
	}

	var body: some View {
		ZStack {
			Color.clear
				.onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }

			if let size {
				HStack(spacing: 0) {
					ZStack {
						Text("\(Int(size.height))")
							.foregroundColor(dimensionsTextColor)
							.padding(.horizontal, 6)
							.padding(.vertical, 3)
							.background(Capsule().fill(dimensionsColor))
							.rotationEffect(.degrees(270))
							.padding(.leading, -5)
					}
					Color.clear
				}

				VStack(spacing: 0) {
					ZStack {
						Text("\(Int(size.width)), \(aspectRatioString)")
							.foregroundColor(dimensionsTextColor)
							.padding(.horizontal, 6)
							.padding(.vertical, 3)
							.background(Capsule().fill(dimensionsColor))
							.padding(1)
					}
					Color.clear
				}
			}
		}
		.overlay(dimension.padding(-dimensionThickness / 2))
		.font(.system(size: 10, weight: .semibold))
	}

	var dimension: some View {
		Rectangle()
			.strokeBorder(dimensionsColor, style: StrokeStyle(lineWidth: dimensionThickness, dash: [dimensionThickness]))
	}
}

@available(iOS 17.0, macOS 14, tvOS 17, watchOS 10, *)
struct PositionOverlay: View {
	@State var viewFrame: CGRect?
	var coordinateSpace = CoordinateSpace.global

	var dimensionsTextColor = Color.white
	var dimensionsColor = Color.red

	var body: some View {
		ZStack {
			Color.clear
				.onGeometryChange(for: CGRect.self, of: { $0.frame(in: coordinateSpace) }) { viewFrame = $0 }

			if let frame = viewFrame {
				Text("(\(Int(frame.minX)), \(Int(frame.minY)))")
					.foregroundColor(dimensionsTextColor)
					.padding(.horizontal, 6)
					.padding(.vertical, 3)
					.background(Capsule().fill(dimensionsColor))
					.padding(1)
			}
		}
		.font(.system(size: 10, weight: .semibold))
	}
}
#endif
#endif
