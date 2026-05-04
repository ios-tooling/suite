//
//  CommunalFetcher.swift
//
//
//  Created by Ben Gottlieb on 4/15/24.
//

import Foundation

public final actor CommunalFetcher<Value: Sendable> {
	private var cached: Value?
	private var inFlight: Task<Value, Error>?
	private let fetcher: @Sendable () async throws -> Value

	public init(fetcher: @Sendable @escaping () async throws -> Value) {
		self.fetcher = fetcher
	}

	public func clear() {
		cached = nil
	}

	public func fetch() async throws -> Value {
		if let cached { return cached }
		if let inFlight { return try await inFlight.value }

		let task = Task { [fetcher] in
			try await fetcher()
		}
		inFlight = task

		do {
			let value = try await task.value
			cached = value
			inFlight = nil
			return value
		} catch {
			inFlight = nil
			throw error
		}
	}
}
