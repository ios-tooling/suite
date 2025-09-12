//
//  View+presentationDetentSizeToFit.swift
//  Internal
//
//  Created by Ben Gottlieb on 11/4/24.
//

import SwiftUI

@available(iOS 16.0, macOS 14, watchOS 9, *)
public extension View {
	func presentationDetentSizeToFit() -> some View {
		PresentationDetentSizeToFit { self }
	}
}

fileprivate extension PreferenceValues {
    #GeneratedPreferenceKey(name: "detentHeight", type: CGFloat.self, defaultValue: 10.0)
}

@available(iOS 16.0, macOS 14, watchOS 9, *)
struct PresentationDetentSizeToFit<Content: View>: View {
	let content: () -> Content
	
	@State private var sheetHeight: CGFloat?
	
	var body: some View {
		content()
			.background {
				GeometryReader { geo in
                    Color.clear.setPreference(\.detentHeight, geo.size.height)
				}
			}
			.getPreference(\.detentHeight) { [$sheetHeight] newHeight in
				 $sheetHeight.wrappedValue = newHeight
			}
			.presentationDetents([sheetHeight == nil ? .medium : .height(sheetHeight!)])

	}
}
