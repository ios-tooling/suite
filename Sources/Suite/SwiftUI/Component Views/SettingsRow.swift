//
//  SettingsRow.swift
//  Suite
//

import SwiftUI

/// A label + detail line with a trailing toggle, sized for settings screens.
@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
public struct ToggleRow: View {
	public let label: String
	public let detail: String
	@Binding public var value: Bool

	public init(label: String, detail: String = "", value: Binding<Bool>) {
		self.label = label
		self.detail = detail
		_value = value
	}

	public init(_ label: String, detail: String = "", value: Binding<Bool>) {
		self.init(label: label, detail: detail, value: value)
	}

	public var body: some View {
		HStack(alignment: .center) {
			VStack(alignment: .leading, spacing: 2) {
				Text(label).font(.callout)
				if !detail.isEmpty {
					if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
						Text(detail).font(.caption).foregroundStyle(.secondary)
					} else {
						Text(detail).font(.caption).foregroundColor(.secondary)
					}
				}
			}
			Spacer()
			Toggle("", isOn: $value).labelsHidden()
		}
		.padding(.vertical, 10)
		.padding(.horizontal, 4)
		Divider()
	}
}

/// A titled section container for settings screens.
@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
public struct SettingsSectionBox<Content: View>: View {
	public let title: String
	@ViewBuilder public let content: Content

	public init(title: String, @ViewBuilder content: () -> Content) {
		self.title = title
		self.content = content()
	}

	public init(_ title: String, @ViewBuilder content: () -> Content) {
		self.init(title: title, content: content)
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
				Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
			} else {
				Text(title).font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
			}
			content
		}
	}
}
