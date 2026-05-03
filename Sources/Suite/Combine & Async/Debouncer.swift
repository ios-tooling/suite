//
//  Debouncer.swift
//
//
//  Created by Ben Gottlieb on 11/28/22.
//

import Foundation

@MainActor public class Debouncer<Value: Sendable>: ObservableObject {
	@Published public var input: Value {
		didSet { scheduleDebounce() }
	}
	@Published public var output: Value

	private let delay: Double
	private var debounceTask: Task<Void, Never>?

	public init(initialValue: Value, delay: Double = 1) {
		self.input = initialValue
		self.output = initialValue
		self.delay = delay
	}

	public func setInput(_ newInput: Value, withoutDebounce: Bool) {
		if withoutDebounce {
			debounceTask?.cancel()
			debounceTask = nil
			output = newInput
		}
		input = newInput
	}

	private func scheduleDebounce() {
		debounceTask?.cancel()
		let nanos = UInt64(delay * 1_000_000_000)
		debounceTask = Task { @MainActor [weak self] in
			try? await Task.sleep(nanoseconds: nanos)
			guard let self, !Task.isCancelled else { return }
			self.output = self.input
		}
	}

	deinit {
		debounceTask?.cancel()
	}
}
