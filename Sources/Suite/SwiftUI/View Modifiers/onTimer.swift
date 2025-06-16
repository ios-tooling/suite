//
//  onTimer.swift
//  Suite
//
//  Created by Ben Gottlieb on 6/8/25.
//

import SwiftUI

// from https://medium.com/parable-engineering/stop-using-timer-publish-in-your-swiftui-views-498ff270860f

struct TimerModifier: ViewModifier {
	@State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>
	private let perform: (Date) -> Void
	
	init(every interval: TimeInterval, tolerance: TimeInterval?, perform: @escaping (Date) -> Void) {
		timer = Timer.publish(every: interval, tolerance: tolerance, on: .main, in: .common)
			.autoconnect()
		self.perform = perform
	}
	
	func body(content: Content) -> some View {
		content
			.onReceive(timer) { date in
				perform(date)
			}
	}
}

extension View {
	func onTimer(every interval: TimeInterval, tolerance: TimeInterval? = nil, perform: @escaping (Date) -> Void) -> some View {
		modifier(TimerModifier(every: interval, tolerance: tolerance, perform: perform))
	}
}
