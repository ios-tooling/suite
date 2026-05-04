//
//  SimpleErrorMessageView.swift
//
//
//  Created by Ben Gottlieb on 9/29/23.
//

import SwiftUI


@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public struct SimpleErrorMessageView: View {
	let error: Error?
	let fallbackText: String?

	public init(error: Error?, fallbackText: String? = nil) {
		self.error = error
		self.fallbackText = fallbackText
	}

	public var body: some View {
		Group {
			if let error {
				Text(error.localizedDescription)
			} else if let fallbackText {
				Text(fallbackText)
			}
		}
		.padding()
	}
}
