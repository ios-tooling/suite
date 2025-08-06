//
//  TouchUpDownActions.swift
//  
//
//  Created by Ben Gottlieb on 5/29/21.
//

#if canImport(Combine)
import SwiftUI

@available(macOS 10.15, iOS 13.0, watchOS 7.0, *)
struct TouchUpDownActions: ViewModifier {
	var touchDown: (() -> Void)?
	var touchUp: (() -> Void)?
	
	func body(content: Content) -> some View {
		content
			.simultaneousGesture(
				DragGesture(minimumDistance: 0)
					.onChanged { _ in touchDown?() }
					.onEnded { _ in touchUp?() }
			)
	}
}

@available(macOS 10.15, iOS 13.0, watchOS 7.0, *)
struct TouchRepeatingView<Content: View>: View {
	let content: Content
	let interval: TimeInterval
	let action: () -> Void
	@State private var task: Task<Void, Never>?
	
	var body: some View {
		content
			.touchActions(touchDown: touchDown, touchUp: touchUp)
			.onDisappear() {
				task?.cancel()
				task = nil
			}
	}
	
	func touchDown() {
		if task != nil { return }
		let action = action
		
		action()
		task = Task {
			var delay: UInt64 = 200_000_000
			
			do {
				while true {
					try await Task.sleep(nanoseconds: delay)
					if delay > 50_000_000 { delay -= 10_000_000 }
					action()
				}
			} catch {
				
			}
		}
	}
	
	func touchUp() {
		task?.cancel()
		task = nil
	}

}

@available(macOS 10.15, iOS 13.0, watchOS 7.0, *)
public extension View {
	func touchActions(touchDown: (() -> Void)? = nil, touchUp: (() -> Void)? = nil) -> some View {
		modifier(TouchUpDownActions(touchDown: touchDown, touchUp: touchUp))
	}
	
	func repeating(interval: TimeInterval = 0.2, action: @escaping () -> Void) -> some View {
		TouchRepeatingView(content: self, interval: interval, action: action)
	}
}
#endif
