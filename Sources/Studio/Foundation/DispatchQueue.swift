//
//  DispatchQueue.swift
//  
//
//  Created by Ben Gottlieb on 7/16/20.
//

import Foundation

extension DispatchQueue {
	@inline(__always)  public static func onMain(async: Bool = false, _ block: @Sendable @escaping () -> Void) {
		if Thread.isMainThread {
			block()
		} else if async {
			DispatchQueue.main.async(execute: block)
		} else {
			DispatchQueue.main.sync(execute: block)
		}
	}
	
	public func async(after: TimeInterval, _ block: @Sendable @escaping () -> Void) {
		asyncAfter(deadline: .now() + after, execute: block)
	}
}
