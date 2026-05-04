//
//  SignificantTimeChangeObserver.swift
//  Strongest
//
//  Created by Ben Gottlieb on 8/24/21.
//  Copyright © 2021 Strongest AI, Inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit

#if os(iOS)
@available(iOS 13.0, *)
public actor SignificantTimeChangeObserver: ObservableObject {
	public static let instance = SignificantTimeChangeObserver()

	init() {
		Task { await self.setup() }
	}

	private func setup() {
		NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: .main) { [weak self] _ in
			Task { await self?.publish() }
		}
	}

	private func publish() {
		objectWillChange.send()
	}
}
#endif
#endif
