//
//  Notification.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/9/19.
//  Copyright © 2019 Stand Alone, Inc. All rights reserved.
//

import Foundation

//public protocol Notifier: RawRepresentable { }
//
//public extension Notifier {
//	var notificationName: Notification.Name { return Notification.Name("\(self.rawValue)") }
//	func notify(object: Any? = nil, info: [String: Any]? = nil) {
//		self.notificationName.notify(object, info: info, forceCurrentThread: false)
//	}
//}
//
//public extension NSObject {
//	func addAsObserver<Note: Notifier>(of note: Note, selector sel: Selector, object: Any? = nil) {
//		NotificationCenter.default.addObserver(self, selector: sel, name: note.notificationName, object: object)
//	}
//}

public extension Notification.Name {
	func notify(_ object: Sendable? = nil, info: [String: Sendable]? = nil, forceCurrentThread: Bool = false) {
		if forceCurrentThread {
			Notification.post(name: self, object: object, userInfo: info)
		} else {
			Notification.postOnMainThread(name: self, object: object, userInfo: info)
		}
	}
}

//extension Notification: @retroactive @unchecked Sendable { }
public extension Notification {
	static func post(name: String, object: Sendable? = nil, userInfo: [String: Sendable]? = nil) {
		self.post(name: Notification.Name(rawValue: name), object: object, userInfo: userInfo)
	}
	
	static func post(name: Notification.Name, object: Sendable? = nil, userInfo: [String: Sendable]? = nil) {
		NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
	}
	
	static func postOnMainThread(name: String, object: Sendable? = nil, userInfo: [String: Sendable]? = nil) {
		self.postOnMainThread(name: Notification.Name(rawValue: name), object: object, userInfo: userInfo)
	}

	static func postOnMainThread(name: Notification.Name, object: Sendable? = nil, userInfo: [String: Sendable]? = nil) {
		MainActor.run {
			self.post(name: name, object: object, userInfo: userInfo)
		}
	}
}
