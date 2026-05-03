//
//  AsyncFlag.swift
//  Suite
//
//  Created by Ben Gottlieb on 12/21/24.
//

import Foundation

public actor AsyncFlag {
	private var isFlagSet = false
	private var waiters: [CheckedContinuation<Void, Never>] = []

	public init() {}

	public func setFlag(to value: Bool = true) {
		isFlagSet = value
		if value {
			let pending = waiters
			waiters.removeAll()
			for waiter in pending { waiter.resume() }
		}
	}

	public func wait() async {
		if isFlagSet { return }
		await withCheckedContinuation { continuation in
			waiters.append(continuation)
		}
	}
}
