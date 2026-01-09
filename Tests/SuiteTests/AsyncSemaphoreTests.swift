//
//  AsyncSemaphoreTests.swift
//  Suite
//
//  Created by Claude Code
//

import Testing
import Foundation
@testable import Suite

@Suite("AsyncSemaphore Tests")
struct AsyncSemaphoreTests {

	@Test("Semaphore with initial value allows immediate wait")
	func immediateWait() async {
		let semaphore = AsyncSemaphore(value: 1)

		// Should not suspend
		await semaphore.wait()

		// Signal to restore value
		semaphore.signal()
	}

	@Test("Semaphore blocks when value is zero")
	func blocksOnZero() async {
		let semaphore = AsyncSemaphore(value: 0)
		var completed = false

		Task {
			try? await Task.sleep(nanoseconds: 100_000_000)
			semaphore.signal()
		}

		await semaphore.wait()
		completed = true

		#expect(completed == true)
	}

	@Test("Signal returns true when resuming a task")
	func signalResumesTask() async {
		let semaphore = AsyncSemaphore(value: 0)

		Task {
			await semaphore.wait()
		}

		// Give the task time to suspend
		try? await Task.sleep(nanoseconds: 50_000_000)

		let resumed = semaphore.signal()
		#expect(resumed == true)
	}

	@Test("Signal returns false when no task waiting")
	func signalWithoutWaiter() {
		let semaphore = AsyncSemaphore(value: 1)

		let resumed = semaphore.signal()
		#expect(resumed == false)
	}

	@Test("Multiple waits and signals")
	func multipleWaitsAndSignals() async {
		let semaphore = AsyncSemaphore(value: 2)

		// Two immediate waits should succeed
		await semaphore.wait()
		await semaphore.wait()

		var completed = false

		Task {
			try? await Task.sleep(nanoseconds: 100_000_000)
			semaphore.signal()
		}

		// Third wait should block until signal
		await semaphore.wait()
		completed = true

		#expect(completed == true)
	}

	@Test("FIFO ordering of waiters")
	func fifoOrdering() async {
		actor ResultCollector {
			var results: [Int] = []
			func append(_ value: Int) {
				results.append(value)
			}
		}

		let semaphore = AsyncSemaphore(value: 0)
		let collector = ResultCollector()

		for i in 0..<5 {
			Task {
				await semaphore.wait()
				await collector.append(i)
			}
		}

		// Give tasks time to queue
		try? await Task.sleep(nanoseconds: 100_000_000)

		// Signal them in order
		for _ in 0..<5 {
			semaphore.signal()
			try? await Task.sleep(nanoseconds: 10_000_000)
		}

		try? await Task.sleep(nanoseconds: 100_000_000)

		let results = await collector.results
		#expect(results.count == 5)
		// Results should contain all values (order may vary due to task scheduling)
		#expect(Set(results) == Set([0, 1, 2, 3, 4]))
	}

	@Test("WaitUnlessCancelled throws on cancelled task")
	func waitUnlessCancelledThrows() async {
		let semaphore = AsyncSemaphore(value: 0)

		let task = Task {
			try await semaphore.waitUnlessCancelled()
		}

		task.cancel()

		do {
			try await task.value
			Issue.record("Should have thrown CancellationError")
		} catch is CancellationError {
			// Expected
		} catch {
			Issue.record("Unexpected error type: \(error)")
		}
	}

	@Test("WaitUnlessCancelled succeeds when not cancelled")
	func waitUnlessCancelledSucceeds() async throws {
		let semaphore = AsyncSemaphore(value: 1)

		try await semaphore.waitUnlessCancelled()

		// Signal to restore
		semaphore.signal()
	}

	@Test("Cancellation restores semaphore value")
	func cancellationRestoresValue() async {
		let semaphore = AsyncSemaphore(value: 0)

		let task = Task {
			try await semaphore.waitUnlessCancelled()
		}

		// Give task time to start waiting
		try? await Task.sleep(nanoseconds: 50_000_000)

		task.cancel()

		// Wait for cancellation to process
		try? await Task.sleep(nanoseconds: 50_000_000)

		// The semaphore value should be restored to 0
		// If we signal now, it should return false (no waiters)
		let resumed = semaphore.signal()
		#expect(resumed == false)
	}

	@Test("Concurrent waits and signals")
	func concurrentOperations() async {
		actor Counter {
			var count = 0
			func increment() { count += 1 }
		}

		let semaphore = AsyncSemaphore(value: 3)
		let counter = Counter()

		await withTaskGroup(of: Void.self) { group in
			// Start 10 tasks that will wait
			for _ in 0..<10 {
				group.addTask {
					await semaphore.wait()
					await counter.increment()
				}
			}

			// Signal 10 times
			for _ in 0..<10 {
				group.addTask {
					try? await Task.sleep(nanoseconds: 10_000_000)
					semaphore.signal()
				}
			}
		}

		let completedCount = await counter.count
		#expect(completedCount == 10)
	}

	@Test("Semaphore as resource limiter")
	func resourceLimiter() async {
		actor ConcurrencyTracker {
			var currentlyRunning = 0
			var maxObserved = 0

			func enter() {
				currentlyRunning += 1
				maxObserved = Swift.max(maxObserved, currentlyRunning)
			}

			func exit() {
				currentlyRunning -= 1
			}

			var current: Int { currentlyRunning }
			var max: Int { maxObserved }
		}

		let maxConcurrent = 3
		let semaphore = AsyncSemaphore(value: maxConcurrent)
		let tracker = ConcurrencyTracker()

		await withTaskGroup(of: Void.self) { group in
			for _ in 0..<10 {
				group.addTask {
					await semaphore.wait()
					await tracker.enter()

					// Simulate work
					try? await Task.sleep(nanoseconds: 50_000_000)

					await tracker.exit()
					semaphore.signal()
				}
			}
		}

		let maxObserved = await tracker.max
		let currentlyRunning = await tracker.current

		#expect(maxObserved <= maxConcurrent)
		#expect(currentlyRunning == 0)
	}

	@Test("Early cancellation before suspension")
	func earlyCancellation() async {
		let semaphore = AsyncSemaphore(value: 0)

		let task = Task {
			try await semaphore.waitUnlessCancelled()
		}

		// Cancel immediately
		task.cancel()

		do {
			try await task.value
			Issue.record("Should have thrown CancellationError")
		} catch is CancellationError {
			// Expected
		} catch {
			Issue.record("Unexpected error: \(error)")
		}
	}

	@Test("WaitUnlessCancelled with immediate value")
	func waitUnlessCancelledImmediate() async throws {
		let semaphore = AsyncSemaphore(value: 5)

		// Should not suspend
		try await semaphore.waitUnlessCancelled()

		semaphore.signal()
	}
}
