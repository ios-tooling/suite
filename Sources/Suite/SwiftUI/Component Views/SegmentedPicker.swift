//
//  SegmentedPicker.swift
//  Suite
//

import SwiftUI

/// A segmented control built from SwiftUI primitives.
/// Works on all Apple platforms and respects the system separator color.
@available(iOS 17, macOS 12, tvOS 15, watchOS 8, *)
public struct SegmentedPicker<T: Hashable>: View {
	public let options: [T]
	@Binding public var selection: T
	public let label: (T) -> String

	public init(options: [T], selection: Binding<T>, label: @escaping (T) -> String) {
		self.options = options
		_selection = selection
		self.label = label
	}

	public init(_ options: [T], selection: Binding<T>, label: @escaping (T) -> String) {
		self.init(options: options, selection: selection, label: label)
	}

	public var body: some View {
		HStack(spacing: 0) {
			ForEach(Array(options.enumerated()), id: \.offset) { _, opt in
				Button(label(opt)) { selection = opt }
					.buttonStyle(SegmentButtonStyle(isSelected: selection == opt))
				if opt != options.last {
					Divider().frame(height: 24)
				}
			}
		}
		.clipShape(RoundedRectangle(cornerRadius: 8))
		.overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator, lineWidth: 0.5))
		.fixedSize()
	}
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public struct SegmentButtonStyle: ButtonStyle {
	let isSelected: Bool

	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.font(.callout)
			.padding(.horizontal, 14)
			.padding(.vertical, 6)
			.background(isSelected ? Color(.init(gray: 0.5, alpha: 0.15)) : Color.clear)
			.foregroundColor(isSelected ? .primary : .secondary)
	}
}

#if DEBUG
@available(iOS 17, macOS 12, tvOS 15, watchOS 8, *)
#Preview {
	SegmentedPicker(["One", "Two", "Three"], selection: .constant("Two")) { $0 }
		.padding()
}
#endif
