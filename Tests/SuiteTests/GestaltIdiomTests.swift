#if os(iOS)
	import Testing
	import UIKit
	@testable import Suite

	@MainActor @Suite("Gestalt idiom override", .serialized)
	struct GestaltIdiomTests {
		@Test("An override makes isOnIPhone and isOnIPad report that idiom, so a harness can show phone layouts on an iPad")
		func overrideWins() {
			defer { Gestalt.idiomOverride = nil }
			Gestalt.idiomOverride = .phone
			#expect(Gestalt.isOnIPhone)
			#expect(!Gestalt.isOnIPad)
			Gestalt.idiomOverride = .pad
			#expect(Gestalt.isOnIPad)
			#expect(!Gestalt.isOnIPhone)
		}

		@Test("Without an override both report the hardware, and deviceIdiom never changes")
		func noOverrideReportsDevice() {
			Gestalt.idiomOverride = .phone
			Gestalt.idiomOverride = nil
			#expect(Gestalt.isOnIPad == (UIDevice.current.userInterfaceIdiom == .pad))
			#expect(Gestalt.isOnIPhone == (UIDevice.current.userInterfaceIdiom == .phone))
			#expect(Gestalt.deviceIdiom == UIDevice.current.userInterfaceIdiom)
		}
	}
#endif
