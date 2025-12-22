//
//  EnviromentEchoingView.swift
//  Suite
//
//  Created by Ben Gottlieb on 12/20/25.
//

import Foundation

extension EnvironmentValues {
	@Entry public var echoedValues: EnvironmentValues?
}

@available(iOS 15, macOS 12, visionOS 1, watchOS 10, *)
public struct EnviromentEchoingView<Content: View>: View {
	var content: () -> Content
	
	@Environment(\.self) var echoedValues

	public init(content: @escaping () -> Content) {
		self.content = content
	}
	
	public var body: some View {
		content()
			.environment(\.echoedValues, echoedValues)
	}
}
