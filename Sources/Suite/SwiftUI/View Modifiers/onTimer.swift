//
//  onTimer.swift
//  Suite
//
//  Created by Ben Gottlieb on 6/8/25.
//

import SwiftUI

struct TimerModifier: ViewModifier {
	let interval: TimeInterval
	let tolerance: TimeInterval?
	let perform: (Date) -> Void

	@State private var task: Task<Void, Never>?

	func body(content: Content) -> some View {
		content
			.onAppear {
				task?.cancel()
				let interval = interval
				let perform = perform
				task = Task { @MainActor in
					let nanos = UInt64(interval * 1_000_000_000)
					while !Task.isCancelled {
						try? await Task.sleep(nanoseconds: nanos)
						if Task.isCancelled { return }
						perform(Date())
					}
				}
			}
			.onDisappear {
				task?.cancel()
				task = nil
			}
	}
}

extension View {
	func onTimer(every interval: TimeInterval, tolerance: TimeInterval? = nil, perform: @escaping (Date) -> Void) -> some View {
		modifier(TimerModifier(interval: interval, tolerance: tolerance, perform: perform))
	}
}
