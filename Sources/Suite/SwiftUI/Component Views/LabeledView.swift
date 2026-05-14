//
//  LabeledView.swift
//
//
//  Created by Ben Gottlieb on 12/3/23.
//

import SwiftUI

public extension EnvironmentValues {
	@Entry var showViewLabels: Bool = false
}

public extension View {
	@ViewBuilder func debugLabel(_ label: String? = nil) -> some View {
		if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15, *) {
			DebugLabeledView(view: self, label: label ?? String(describing: self))
		} else {
			self
		}
	}
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15,*)
struct DebugLabeledView<Content: View>: View {
	let view: Content
	let label: String
	@Environment(\.showViewLabels) var showViewLabels
	
	var body: some View {
		if showViewLabels {
			view
				.overlay(alignment: .topLeading) {
					Text(label)
						.font(.system(size: 9, weight: .semibold, design: .rounded))
						.foregroundColor(.yellow)
						.padding(2)
						.background(.red)
				}
		} else {
			view
		}
	}
}
