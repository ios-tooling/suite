//
//  SwiftUIView.swift
//  
//
//  Created by Ben Gottlieb on 3/21/22.
//

import SwiftUI

extension View {

	 /// Calls the completion handler whenever an animation on the given value completes.
	 /// - Parameters:
	 ///   - value: The value to observe for animations.
	 ///   - completion: The completion callback to call once the animation completes.
	 /// - Returns: A modified `View` instance with the observer attached.
	 func onAnimationCompleted<Value: VectorArithmetic>(for value: Value, completion: @escaping () -> Void) -> ModifiedContent<Self, AnimationCompletionObserverModifier<Value>> {
		  return modifier(AnimationCompletionObserverModifier(observedValue: value, completion: completion))
	 }
}

/// An animatable modifier that is used for observing animations for a given animatable value.
@MainActor struct AnimationCompletionObserverModifier<Value>: ViewModifier, Animatable where Value: VectorArithmetic & Sendable {
	
	/// While animating, SwiftUI changes the old input value to the new target value using this property. This value is set to the old value until the animation completes.
	var animatableData: Value {
		didSet {
			notifyCompletionIfFinished()
		}
	}
	
	/// The target value for which we're observing. This value is directly set once the animation starts. During animation, `animatableData` will hold the oldValue and is only updated to the target value once the animation completes.
	private var targetValue: Value
	
	/// The completion callback which is called once the animation completes.
	private var completion: () -> Void
	
	init(observedValue: Value, completion: @escaping () -> Void) {
		self.completion = completion
		self.animatableData = observedValue
		targetValue = observedValue
	}
	
	/// Verifies whether the current animation is finished and calls the completion callback if true.
	private func notifyCompletionIfFinished() {
		guard animatableData == targetValue else { return }

		// Dispatch to the next runloop to avoid "Modifying state during view update".
		// MainActor.run from a sync main-actor context is essentially synchronous —
		// it does NOT defer. A Task hop does.
		let completion = completion
		Task { @MainActor in completion() }
	}
	
	func body(content: Content) -> some View {
		/// We're not really modifying the view so we can directly return the original input value.
		return content
	}
}
