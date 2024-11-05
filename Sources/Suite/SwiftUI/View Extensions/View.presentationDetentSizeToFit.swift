//
//  View+presentationDetentSizeToFit.swift
//  Internal
//
//  Created by Ben Gottlieb on 11/4/24.
//

import SwiftUI

public extension View {
	func presentationDetentSizeToFit() -> some View {
		PresentationDetentSizeToFit { self }
	}
}

extension PreferenceValues {
	#GeneratedPreferenceKey(name: "detentHeight", type: CGFloat, defaultValue: 0.0)
}

struct PresentationDetentSizeToFit<Content: View>: View {
	let content: () -> Content
	
	@State private var sheetHeight = CGFloat.zero
	
	var body: some View {
		content()
			.background {
				GeometryReader { geo in
					Color.clear.preference(key: PreferenceValues.GeneratedPreferenceKey_detentHeight.self, value: geo.size.height)
				}
			}
			.onPreferenceChange(PreferenceValues.GeneratedPreferenceKey_detentHeight.self) { newHeight in
				 sheetHeight = newHeight
			}
			.presentationDetents([.height(sheetHeight)])

	}
}
