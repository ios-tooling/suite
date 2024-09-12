//
//  ObservableObjectPublisher.swift
//  
//
//  Created by ben on 8/26/20.
//


#if canImport(Combine)

import Foundation
import OSLog
import Combine

@available(iOS 14.0, macOS 11.0, *)
fileprivate let logger = Logger(subsystem: "suite", category: "observableObject")

@available(OSX 11, iOS 14.0, watchOS 8.0, *)
struct ObserverMonitor<Pub: ObservableObjectPublisher, Content: View & Sendable>: View {
	let target: Pub
	let content: Content
	let message: String?
	var cancellable: AnyCancellable?

	init(_ target: Pub, content: Content, message: String? = nil) {
		self.target = target
		self.content = content
		self.message = message
		cancellable = target.eraseToAnyPublisher().sink { item in
			logger.info("\(String(describing: item)) \(message ?? String(describing: content))")
		}
	}

	var body: some View {
		content
	}
}

@available(OSX 11, iOS 14.0, watchOS 8.0, *)
extension View where Self: Sendable {
	public func monitor(_ target: ObservableObjectPublisher, _ message: String? = nil) -> some View {
		ObserverMonitor(target, content: self, message: message)
	}
	
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, *)
extension ObservableObjectPublisher: @unchecked @retroactive Sendable { }

@available(OSX 10.15, iOS 13.0, watchOS 6.0, *)
public extension ObservableObjectPublisher {
	func sendOnMain() {
		if Thread.isMainThread {
			send()
		} else {
			DispatchQueue.main.async { self.send() }
		}
	}
	
	func monitor(message: String) {
		eraseToAnyPublisher()
			.onSuccess() { _ in logg(message) }
	}
}

#endif
