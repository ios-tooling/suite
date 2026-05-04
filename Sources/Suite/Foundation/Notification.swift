//
//  Notification.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/9/19.
//  Copyright © 2019 Stand Alone, Inc. All rights reserved.
//

import Foundation

public extension Notification.Name {
	func notify(_ object: Sendable? = nil, info: [String: Sendable]? = nil, forceCurrentThread: Bool = false) {
		if forceCurrentThread {
			Notification.post(name: self, object: object, userInfo: info)
		} else {
			Notification.postOnMainThread(name: self, object: object, userInfo: info)
		}
	}
}

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
