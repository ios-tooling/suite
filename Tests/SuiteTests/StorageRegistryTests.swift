//
//  StorageRegistryTests.swift
//  Suite
//
//  Created by Ben Gottlieb on 8/19/26.
//

import Testing
import Foundation
@testable import Suite

@MainActor private final class Probe: SweepableStorage {
	var swept = false
	nonisolated func clearForSignOut() { Task { @MainActor in swept = true } }
}

// StorageRegistry needs Synchronization, so every body checks availability rather than the
// suite — Swift Testing won't accept @available on @Suite or @Test.
@Suite("StorageRegistry")
@MainActor struct StorageRegistryTests {
	@Test("Registration is observable without sweeping")
	func registrationIsObservable() {
		guard #available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let probe = Probe()
		#expect(!StorageRegistry.isRegistered(probe))

		StorageRegistry.register(probe)

		#expect(StorageRegistry.isRegistered(probe))
	}

	@Test("Identity, not equality: another instance isn't registered")
	func distinguishesInstances() {
		guard #available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		let registered = Probe()
		let other = Probe()
		StorageRegistry.register(registered)

		#expect(StorageRegistry.isRegistered(registered))
		#expect(!StorageRegistry.isRegistered(other))
	}

	// the boxes are weak, so a released store leaves a nil behind; the sweep has to step
	// over it and still reach everything after it
	@Test("A released storage doesn't break the sweep")
	func toleratesDeallocatedStorage() async {
		guard #available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) else { return }
		var probe: Probe? = Probe()
		StorageRegistry.register(probe!)
		let survivor = Probe()
		StorageRegistry.register(survivor)

		probe = nil
		StorageRegistry.clearAllRegistered()

		for _ in 0..<100 {
			if survivor.swept { break }
			await Task.yield()
		}
		#expect(survivor.swept)
	}
}
