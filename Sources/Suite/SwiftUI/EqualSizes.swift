//
//  EqualSizes.swift
//
//
//  Created by Ben Gottlieb on 3/31/24.
//

import SwiftUI

public extension View {
	func makeEqualSized(axis: Axis.Set = .horizontal, alignment: Alignment = .center) -> some View {
		self.modifier(EqualSizeModifier(axis: axis, alignment: alignment))
	}
	
	func makeEqualSizedSubviews() -> some View {
		self.modifier(EqualSizedChildrenModifier())
	}
}

extension PreferenceValues {
	#GeneratedPreferenceKey(name: "equalSizeSizes", type: [CGSize], defaultValue: [])
}

extension EnvironmentValues {
	@GeneratedEnvironmentKey var enforcedSize: CGSize?
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

struct EqualSizedChildrenModifier: ViewModifier {
	@State private var reportedSubviewSizes: [CGSize] = []
	
	func body(content: Content) -> some View {
		content
			.getPreference(\.equalSizeSizes) { sizes in
				reportedSubviewSizes = sizes
			}
			.environment(\.enforcedSize, reportedSubviewSizes.maxSize)
	}
}
