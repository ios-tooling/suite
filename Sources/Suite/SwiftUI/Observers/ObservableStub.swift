//
//  ObservableStub.swift
//  
//
//  Created by Ben Gottlieb on 1/3/22.
//

import SwiftUI

#if canImport(Combine)

@available(OSX 10.15, iOS 13.0, watchOS 6.0, *)
@MainActor public class ObservableStub: ObservableObject {
	public init() { }

	public func nudge() {
		objectWillChange.send()
	}
}
#endif
