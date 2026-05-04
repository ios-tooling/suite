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

		let task = Task { await flag.waitForReady() }

		// Deterministic barrier: wait until the task has registered as a waiter.
		await flag.waitUntilWaiters(count: 1)

		// At this point the flag is blocking the task. Trigger it.
		flag.makeReady()

		// `await task.value` returns iff the flag fired; if it doesn't,
		// the test would hang and Swift Testing's per-test timeout would catch it.
		await task.value
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

		var tasks: [Task<Void, Never>] = []
		for _ in 0..<5 {
			tasks.append(Task {
				await flag.waitForReady()
				await counter.increment()
			})
		}

		// Deterministic barrier: every waiter has registered.
		await flag.waitUntilWaiters(count: 5)

		flag.makeReady()

		for task in tasks { await task.value }

		let count = await counter.count
		#expect(count == 5)
	}

	@Test("Set to true works like makeReady")
	func setTrue() async {
		let flag = ReadyFlag()

		let task = Task { await flag.waitForReady() }

		await flag.waitUntilWaiters(count: 1)

		flag.set(true)

		await task.value
	}

	@Test("Set to false does nothing")
	func setFalse() async {
		let flag = ReadyFlag()

		flag.set(false)

		let task = Task { await flag.waitForReady() }

		// Wait until the task is registered as a waiter — set(false) didn't fire.
		await flag.waitUntilWaiters(count: 1)

		// Verify the task is still suspended (it's a waiter, not yet completed).
		#expect(flag.storage.waiterCount == 1)

		// Cancel by triggering — proves the flag is still capable of firing.
		flag.makeReady()
		await task.value
	}

	@Test("Sequential ready flags")
	func sequentialFlags() async {
		let flag1 = ReadyFlag()
		let flag2 = ReadyFlag()

		actor Steps {
			var step1 = false
			var step2 = false
			func setStep1() { step1 = true }
			func setStep2() { step2 = true }
		}
		let steps = Steps()

		let runner1 = Task {
			await flag1.waitForReady()
			await steps.setStep1()
			flag2.makeReady()
		}

		let runner2 = Task {
			await flag2.waitForReady()
			await steps.setStep2()
		}

		// Both runners are now suspended on their respective flags.
		await flag1.waitUntilWaiters(count: 1)
		await flag2.waitUntilWaiters(count: 1)

		flag1.makeReady()

		// Drive both runners to completion deterministically.
		await runner1.value
		await runner2.value

		let s1 = await steps.step1
		let s2 = await steps.step2
		#expect(s1)
		#expect(s2)
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
				await flag.waitUntilWaiters(count: 10)
				await flag.makeReady()
			}
		}

		let completionCount = await counter.count
		#expect(completionCount == 10)
	}
}
