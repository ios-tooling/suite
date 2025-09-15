//
//  safeGlassButton.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/12/25.
//

import SwiftUI

@available(iOS 15.0, macOS 13, watchOS 9, *)
public extension View {
	@ViewBuilder func safeGlassButton(prominent: Bool = false) -> some View {
		if #available(iOS 26.0, macOS 26, *) {
			if prominent {
				self
					.buttonStyle(.glassProminent)
			} else {
				self
					.buttonStyle(.glass)
			}
		} else {
			if prominent {
				self
					.buttonStyle(.borderedProminent)
			} else {
				self
					.buttonStyle(.bordered)
			}
		}
	}
}
