//
//  Console.swift
//  Prometheus5
//
//  Created by Ben Gottlieb on 10/8/23.
//

import SwiftUI

@MainActor public class Console: ObservableObject {
	public static let instance = Console()
	public static let messageCap = 500

	@Published public var isVisible = false
	@Published public var hasUnseenMessages = false
	@Published public var messages: [Message] = []

	public static func print(_ content: String) {
		instance.print(content)
	}

	public struct Message: Identifiable {
		public let id = UUID()
		public let body: String
		public let error: Error?
	}

	public func print(_ content: String) {
		append(.init(body: content, error: nil))
	}

	public func print(_ content: String, error: (any Error)?) {
		append(.init(body: content, error: error))
	}

	private func append(_ message: Message) {
		messages.append(message)
		if messages.count > Self.messageCap {
			messages.removeFirst(messages.count - Self.messageCap)
		}
		if !isVisible { hasUnseenMessages = true }
	}

	public func clear() {
		messages = []
	}
}

@MainActor public struct ConsoleView: View {
	@ObservedObject var console = Console.instance
	
	public init() { }
	public var body: some View {
		VStack {
			Spacer()
			
			if let last = console.messages.last {
				Text(last.body)
					.font(.caption)
					.frame(maxWidth: .infinity)
					.background(Color.white)
					.foregroundColor(.black)
					.padding(2)
					.border(.black, width: 2)
					.padding()
			}
		}
	}
}
