//
//  SignificantTimeChangeObserver.swift
//  Strongest
//
//  Created by Ben Gottlieb on 8/24/21.
//  Copyright © 2021 Strongest AI, Inc. All rights reserved.
//

#if canImport(Combine)
#if canImport(UIKit)
import UIKit
import Combine

#if os(iOS)
@available(iOS 13.0, *)
public actor SignificantTimeChangeObserver: ObservableObject {
	public static let instance = SignificantTimeChangeObserver()

	var cancellable: AnyCancellable?

	init() {
		Task { await self.setup() }
	}
	
	func setup() {
		cancellable = UIApplication.significantTimeChangeNotification.publisher()
			.sink { _ in
				self.objectWillChange.send()
			}
	}
}
#endif
#endif
#endif
