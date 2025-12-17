//
//  ThreadsafeMutex.swift
//  Suite
//
//  Created by Ben Gottlieb on 8/4/25.
//

import Foundation
import os.lock

@available(iOS 16.0, watchOS 9, macOS 14, *)
final public class ThreadsafeMutex<T: Sendable>: @unchecked Sendable {
	private let lock: OSAllocatedUnfairLock<T>
	
	public init(_ v: T) {
		lock = .init(initialState: v)
	}
	
	nonisolated public var value: T {
		get {
			lock.withLock { value in value }
		}
		
		set {
			lock.withLock { value in value = newValue }
		}
	}
	
	nonisolated public func set(_ value: T) {
		self.value = value
	}
	
	nonisolated public func perform(block: @Sendable (inout T) -> Void) {
		lock.withLock { value in
			block(&value)
		}
	}
}

/*
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
	 
	 nonisolated public func perform(block: (inout T) -> Void) {
		 os_unfair_lock_lock(&lock)
		 block(&_value)
		 os_unfair_lock_unlock(&lock)
	 }
 }

 */
