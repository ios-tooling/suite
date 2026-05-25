//
//  EqualSizes.swift
//
//
//  Created by Ben Gottlieb on 3/31/24.
//

import SwiftUI

@available(iOS 17.0, macOS 14, tvOS 17, watchOS 10, *)
public extension View {
	func makeEqualSized(axis: Axis.Set = .horizontal, alignment: Alignment = .center) -> some View {
		self.modifier(EqualSizeModifier(axis: axis, alignment: alignment))
	}

	func makeEqualSizedSubviews() -> some View {
		self.modifier(EqualSizedChildrenModifier())
	}
}

extension PreferenceValues {
    #GeneratedPreferenceKey(name: "equalSizeSizes", type: [CGSize].self, defaultValue: [])
}

extension EnvironmentValues {
	@Entry var enforcedSize: CGSize?
}

extension [CGSize] {
	var maxSize: CGSize? {
		var maxSize = CGSize.zero
		
		for size in self {
			maxSize.width = Swift.max(maxSize.width, size.width)
			maxSize.height = Swift.max(maxSize.height, size.height)
		}
		
		return maxSize == .zero ? nil : maxSize
	}
}

@available(iOS 17.0, macOS 14, tvOS 17, watchOS 10, *)
struct EqualSizeModifier: ViewModifier {
	let axis: Axis.Set
	let alignment: Alignment
	@State private var reportedSize: CGSize = .zero
	@Environment(\.enforcedSize) var enforcedSize: CGSize?
	
	func body(content: Content) -> some View {
		content
			.sizeReporting($reportedSize)
            .setPreference(\.equalSizeSizes, [reportedSize])
			.frame(width: axis.contains(.horizontal) ? enforcedSize?.width : nil, height: axis.contains(.vertical) ? enforcedSize?.height : nil, alignment: alignment)
	}
}

@available(iOS 17.0, macOS 14, tvOS 17, watchOS 10, *)
struct EqualSizedChildrenModifier: ViewModifier {
	@State private var reportedSubviewSizes: [CGSize] = []
	
	func body(content: Content) -> some View {
		content
            .getPreference(\.equalSizeSizes.self) { sizes in
                reportedSubviewSizes = sizes
            }
			.environment(\.enforcedSize, reportedSubviewSizes.maxSize)
	}
}
