//
//  Deferred.swift
//  
//
//  Created by Ben Gottlieb on 12/21/20.
//

#if canImport(Combine)
import SwiftUI

@available(OSX 12, iOS 15.0, watchOS 8.0, *)
public struct Deferred<Content: View>: View {
	var builder: () -> Content
	@State var content: Content?
	let delay: TimeInterval?
	
	public init(delay: TimeInterval? = nil,  @ViewBuilder _ content: @escaping () -> Content) {
		self.delay = delay
		builder = content
	}
	
	public var body: some View {
		HStack() {
			if let content = content { content }
		}
		.task {
			if let delay {
				try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
			}
			self.content = builder()
		}
	}
}

#endif
