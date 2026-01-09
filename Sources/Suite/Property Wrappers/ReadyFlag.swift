//
//  ReadyFlag.swift
//  
//
//  Created by Ben Gottlieb on 5/14/22.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
@MainActor public struct ReadyFlag {
	public func waitForReady() async {
		if storage.value { return }
		let _: Bool = await withUnsafeContinuation { continuation in
			storage.append(continuation)
		}
	}
	
	public init() {
	}
	
	public func makeReady() { set(true) }
	public func set(_ newValue: Bool) { storage.set(newValue) }

	let storage = Storage()
	
	class Storage {
		private let _lock: UnsafeMutablePointer<os_unfair_lock_s>

		init() {
			_lock = UnsafeMutablePointer<os_unfair_lock_s>.allocate(capacity: 1)
			_lock.initialize(to: os_unfair_lock_s())
		}
		
		deinit {
			_lock.deinitialize(count: 1)
			_lock.deallocate()
		}

		var value = false
		var continuations: [UnsafeContinuation<Bool, Never>] = []
		
		func append(_ continuation: UnsafeContinuation<Bool, Never>) {
			os_unfair_lock_lock(_lock)
			continuations.append(continuation)
			os_unfair_lock_unlock(_lock)
		}
		
		func set(_ newValue: Bool) {
			os_unfair_lock_lock(_lock)
			defer { os_unfair_lock_unlock(_lock) }
			
			if !newValue { return }
			value = newValue
			let continues = continuations
			continuations = []
			for con in continues { con.resume(returning: true) }
		}
	}
}
