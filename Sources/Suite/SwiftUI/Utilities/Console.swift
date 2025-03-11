//
//  Console.swift
//  Prometheus5
//
//  Created by Ben Gottlieb on 10/8/23.
//

import SwiftUI

@MainActor public class Console: ObservableObject {
	public static let instance = Console()
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
		messages.append(.init(body: content, error: nil))
		if !isVisible { hasUnseenMessages = true }
	}
	
	public func print(_ content: String, error: (any Error)?) {
		messages.append(.init(body: content, error: error))
		if !isVisible { hasUnseenMessages = true }
	}
	
	public func writeToFile() {
		
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
