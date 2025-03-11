//
//  Notification.swift
//  
//
//  Created by Ben Gottlieb on 9/18/21.
//

import Foundation

#if canImport(Combine)
import Combine
import SwiftUI

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
@MainActor public class NotificationObserver: ObservableObject {
	var token: Any?
	public init(_ name: Notification.Name, _ object: Any? = nil) {
		token = NotificationCenter.default.addObserver(forName: name, object: object, queue: .main, using: { [weak self] note in
			self?.objectWillChange.send()
		})
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension Notification.Name {
	func publisher(object: AnyObject? = nil) -> NotificationCenter.Publisher {
		NotificationCenter.default.publisher(for: self, object: object)
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension View {
	func onReceive(_ name: Notification.Name, object: AnyObject? = nil, perform: @escaping (Notification) -> Void) -> some View {
		self
			.onReceive(name.publisher(object: object)) { note in
				perform(note)
			}
	}
}


#endif

