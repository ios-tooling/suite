//
//  AsyncFlag.swift
//  Suite
//
//  Created by Ben Gottlieb on 12/21/24.
//

import Foundation

public actor AsyncFlag {
	private var continuation: AsyncStream<Void>.Continuation?
	private var isFlagSet = false
	private var stream: AsyncStream<Void>?
	
	public init() {
		Task { await self.setupContinuation() }
	}
	
	func setupContinuation() {
		stream = AsyncStream<Void> { continuation in
			self.continuation = continuation
		}
	}
	
	public func setFlag(to value: Bool = true) {
		isFlagSet = value
		continuation?.yield() // Notify waiting tasks
	}
	
	public func wait() async {
		while !isFlagSet {
			for await _ in AsyncStream<Void>(unfolding: {  }) {
				break // break once a signal is received
			}
		}
	}
}
