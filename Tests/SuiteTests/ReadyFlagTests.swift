//
//  ReadyFlagTests.swift
//  Suite
//
//  Created by Claude Code
//

import Testing
import Foundation
@testable import Suite

@MainActor
@Suite("ReadyFlag Tests")
struct ReadyFlagTests {

	@Test("ReadyFlag starts not ready")
	func startsNotReady() async {
		let flag = ReadyFlag()

		var completed = false

		Task {
			await flag.waitForReady()
			completed = true
		}

		// Give task time to start waiting
		try? await Task.sleep(nanoseconds: 50_000_000)

		#expect(completed == false)

		// Make it ready
		flag.makeReady()

		try? await Task.sleep(nanoseconds: 50_000_000)

		#expect(completed == true)
	}

	@Test("ReadyFlag when already ready returns immediately")
	func alreadyReady() async {
		let flag = ReadyFlag()

		flag.makeReady()

		// Should return immediately
		await flag.waitForReady()

		// Test passes if we get here without hanging
	}

	@Test("Multiple waiters are all notified")
	func multipleWaiters() async {
		actor Counter {
			var count = 0
			func increment() { count += 1 }
		}

		let flag = ReadyFlag()
		let counter = Counter()

		for _ in 0..<5 {
			Task {
				await flag.waitForReady()
				await counter.increment()
			}
		}

		// Give tasks time to start waiting
		try? await Task.sleep(nanoseconds: 100_000_000)

		await flag.makeReady()

		// Give tasks time to complete
		try? await Task.sleep(nanoseconds: 100_000_000)

		let count = await counter.count
		#expect(count == 5)
	}

	@Test("Set to true works like makeReady")
	func setTrue() async {
		let flag = ReadyFlag()

		var completed = false

		Task {
			await flag.waitForReady()
			completed = true
		}

		try? await Task.sleep(nanoseconds: 50_000_000)

		flag.set(true)

		try? await Task.sleep(nanoseconds: 50_000_000)

		#expect(completed == true)
	}

	@Test("Set to false does nothing")
	func setFalse() async {
		let flag = ReadyFlag()

		flag.set(false)

		var completed = false

		Task {
			await flag.waitForReady()
			completed = true
		}

		try? await Task.sleep(nanoseconds: 50_000_000)

		#expect(completed == false)
	}

	@Test("Sequential ready flags")
	func sequentialFlags() async {
		let flag1 = ReadyFlag()
		let flag2 = ReadyFlag()

		var step1 = false
		var step2 = false

		Task {
			await flag1.waitForReady()
			step1 = true
			flag2.makeReady()
		}

		Task {
			await flag2.waitForReady()
			step2 = true
		}

		try? await Task.sleep(nanoseconds: 50_000_000)

		#expect(step1 == false)
		#expect(step2 == false)

		flag1.makeReady()

		try? await Task.sleep(nanoseconds: 100_000_000)

		#expect(step1 == true)
		#expect(step2 == true)
	}

	@Test("Concurrent waiters with delayed ready")
	func concurrentWaiters() async {
		actor Counter {
			var count = 0
			func increment() { count += 1 }
		}

		let flag = ReadyFlag()
		let counter = Counter()

		await withTaskGroup(of: Void.self) { group in
			for _ in 0..<10 {
				group.addTask {
					await flag.waitForReady()
					await counter.increment()
				}
			}

			group.addTask {
				try? await Task.sleep(nanoseconds: 100_000_000)
				await flag.makeReady()
			}
		}

		let completionCount = await counter.count
		#expect(completionCount == 10)
	}
}
