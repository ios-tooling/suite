//
//  ObservableActor.swift
//  Suite
//
//  Created by Ben Gottlieb on 10/11/24.
//

import SwiftUI
import Combine

@MainActor public class ObservableActor<Content: Sendable & ObservableObject>: ObservableObject {
	public var target: Content!
	var cancellable: AnyCancellable?
	
	@MainActor public init(_ target: @escaping () async -> Content) async {
		self.target = await target()
		
		cancellable = self.target?.objectWillChange.sink { [weak self] _ in
			self?.objectWillChange.send()
		}
	}
}
