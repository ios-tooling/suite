//
//  Observables.swift
//  
//
//  Created by Ben Gottlieb on 5/12/22.
//

import Foundation

@MainActor public class NotificationWatcher: NSObject, ObservableObject {
	public init(_ name: Notification.Name, object: Any? = nil) {
		super.init()
		NotificationCenter.default.addObserver(self, selector: #selector(notify), name: name, object: object)
	}

	@objc private func notify() {
		objectWillChange.send()
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}

public class PokeableObject: ObservableObject {
	public init() {
		
	}
	
	public func poke() {
		objectWillChange.send()
	}
}
