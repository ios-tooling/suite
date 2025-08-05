//
//  ThreadsafeMutex.swift
//  Suite
//
//  Created by Ben Gottlieb on 8/4/25.
//

import Foundation
import os.lock

final public class ThreadsafeMutex<T>: @unchecked Sendable {
	private var _value: T
	private var lock = os_unfair_lock_s()
	
	public init(_ v: T) {
		_value = v
	}
	
	nonisolated public var value: T {
		get {
			os_unfair_lock_lock(&lock)
			let value = _value
			os_unfair_lock_unlock(&lock)
			return value
		}
		
		set {
			set(newValue)
		}
	}
	
	nonisolated public func set(_ value: T) {
		os_unfair_lock_lock(&lock)
		_value = value
		os_unfair_lock_unlock(&lock)
	}
	
	public func perform(block: (inout T) -> Void) {
		os_unfair_lock_lock(&lock)
		block(&_value)
		os_unfair_lock_unlock(&lock)
	}
}
