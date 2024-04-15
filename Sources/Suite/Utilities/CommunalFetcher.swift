//
//  CommunalFetcher.swift
//  
//
//  Created by Ben Gottlieb on 4/15/24.
//

import Foundation
import Combine

public final class CommunalFetcher<Value> {
	var value: CurrentValueSubject<Value?, Error> = .init(nil)
	var inProgress = false
	var fetcher: () async throws -> Value
	var cancellables: Set<AnyCancellable> = []
	
	public init(fetcher: @escaping () async throws -> Value) {
		self.fetcher = fetcher
	}
	
	public func clear() {
		value.value = nil
	}
	
	public func fetch() async throws -> Value {
		if let current = value.value { return current }
		if inProgress {
			return try await withCheckedThrowingContinuation { continuation in
				self.value
					.sink(receiveCompletion: { completionValue in
						if case let .failure(error) = completionValue {
							continuation.resume(throwing: error)
						}
					}, receiveValue: { new in
						if let new {
							continuation.resume(returning: new)
						}
					})
					.store(in: &cancellables)
			}
		}
		
		inProgress = true
		do {
			let value = try await fetcher()
			self.value.value = value
			inProgress = false
			cancellables = []
			return value
		} catch {
			value.send(completion: .failure(error))
			inProgress = false
			cancellables = []
			throw error
		}
	}
}

