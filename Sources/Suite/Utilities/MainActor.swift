//
//  Animation.swift
//
//
//  Created by Ben Gottlieb on 7/5/23.
//

import SwiftUI

extension MainActor {
	public static func run(_ block: @Sendable @escaping () -> Void) {
		Task { await MainActor.run { block() }}
	}
}


@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public func withAnimationOnMain<Result>(_ animation: Animation? = .default, completionCriteria: AnimationCompletionCriteria = .logicallyComplete, _ body: @Sendable @escaping () -> Result, completion: @Sendable @escaping () -> Void) {
	if Thread.isMainThread {
		_ = withAnimation(animation, completionCriteria: completionCriteria, body, completion: completion)
	} else {
		MainActor.run { _ = withAnimation(animation, completionCriteria: completionCriteria, body, completion: completion) }
	}
}

public func withAnimationOnMain<Result>(_ animation: Animation? = .default, _ body: @Sendable @escaping () -> Result) {
	if Thread.isMainThread {
		_ = withAnimation(animation, body)
	} else {
		MainActor.run { _ = withAnimation(animation, body) }
	}
}
