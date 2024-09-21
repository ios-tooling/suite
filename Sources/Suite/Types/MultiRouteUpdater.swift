//
//  MultiRouteUpdater.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/20/24.
//

import Foundation

public actor MultiRouteUpdater<Result: Sendable> {
	var action: () async throws -> Result
	public init(update: @escaping () async throws -> Result) {
		action = update
	}
	
	var isUpdating = false
	
	var continuations: [CheckedContinuation<Result, Error>] = []
	
	public func callAsFunction() async throws -> Result {
		try await update()
	}
	
	public func update() async throws -> Result {
		if isUpdating {
			return try await withCheckedThrowingContinuation { continuation in
				continuations.append(continuation)
			}
		}
		isUpdating = true
		defer {
			isUpdating = false
			continuations = []
		}

		do {
			let result = try await action()
			for continuation in continuations {
				continuation.resume(returning: result)
			}
			return result
		} catch {
			for continuation in continuations {
				continuation.resume(throwing: error)
			}
			throw error
		}
	}
}
