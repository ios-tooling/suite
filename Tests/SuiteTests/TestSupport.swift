//
//  TestSupport.swift
//  Suite
//
//  Helpers for the test target. Not exported.
//

import Foundation
@testable import Suite

/// Yields cooperatively several times so any spawned `Task`s have a chance to
/// reach a suspension point. Use in place of fixed-duration `Task.sleep` when
/// the only thing you're waiting for is "let the scheduler run my child task
/// up to its first await."
///
/// Defaults are tuned for tests where 1–10 child tasks need to register a
/// suspension before the test can proceed; bump `iterations` if you spawn many.
func yieldUntilSuspended(iterations: Int = 25) async {
	for _ in 0..<iterations {
		await Task.yield()
	}
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
@MainActor extension ReadyFlag {
	/// Yields until at least `count` tasks are suspended on `waitForReady()`.
	/// Use as a deterministic barrier in tests: spawn N waiter tasks, then
	/// `await flag.waitUntilWaiters(count: N)` before triggering, so that the
	/// trigger is guaranteed to land after every waiter has registered.
	func waitUntilWaiters(count: Int) async {
		while storage.waiterCount < count { await Task.yield() }
	}
}
