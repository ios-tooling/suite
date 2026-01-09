//
//  ThreadsafeMutexTests.swift
//  Suite
//
//  Created by Claude Code
//

import Testing
import Foundation
@testable import Suite

@Suite("ThreadsafeMutex Tests")
struct ThreadsafeMutexTests {

	@available(iOS 16.0, watchOS 9, macOS 14, *)
	@Test("Basic get and set")
	func basicGetSet() {
		let mutex = ThreadsafeMutex(42)
		#expect(mutex.value == 42)

		mutex.value = 100
		#expect(mutex.value == 100)
	}

	@available(iOS 16.0, watchOS 9, macOS 14, *)
	@Test("Set method")
	func setMethod() {
		let mutex = ThreadsafeMutex("initial")
		mutex.set("updated")
		#expect(mutex.value == "updated")
	}

	@available(iOS 16.0, watchOS 9, macOS 14, *)
	@Test("Perform block modification")
	func performBlock() {
		let mutex = ThreadsafeMutex(0)

		mutex.perform { value in
			value += 1
		}

		#expect(mutex.value == 1)

		mutex.perform { value in
			value *= 2
		}

		#expect(mutex.value == 2)
	}

	@available(iOS 16.0, watchOS 9, macOS 14, *)
	@Test("Concurrent write access")
	func concurrentWrites() async {
		let mutex = ThreadsafeMutex(0)

		await withTaskGroup(of: Void.self) { group in
			for _ in 0..<100 {
				group.addTask {
					mutex.perform { value in
						value += 1
					}
				}
			}
		}

		#expect(mutex.value == 100)
	}

	@available(iOS 16.0, watchOS 9, macOS 14, *)
	@Test("Thread safety with complex types")
	func complexTypes() async {
		struct Counter: Sendable {
			var count: Int
			var name: String
		}

		let mutex = ThreadsafeMutex(Counter(count: 0, name: "test"))

		await withTaskGroup(of: Void.self) { group in
			for _ in 0..<100 {
				group.addTask {
					mutex.perform { value in
						value.count += 1
					}
				}
			}
		}

		let final = mutex.value
		#expect(final.count == 100)
		#expect(final.name == "test")
	}
}
