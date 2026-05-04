//
//  GestaltTests.swift
//  Suite
//
//  Created by Claude Code
//

import Testing
import Foundation
@testable import Suite

@Suite("Gestalt Tests")
struct GestaltTests {

	@Test("Distribution enum comparison")
	func distributionTypes() {
		#expect(Gestalt.distribution == .development || Gestalt.distribution == .testflight || Gestalt.distribution == .appStore)
	}

	@Test("Debug level comparison")
	func debugLevelComparison() {
		#expect(Gestalt.DebugLevel.none < Gestalt.DebugLevel.testFlight)
		#expect(Gestalt.DebugLevel.testFlight < Gestalt.DebugLevel.internalTesting)
		#expect(Gestalt.DebugLevel.internalTesting < Gestalt.DebugLevel.debugging)
		#expect(!(Gestalt.DebugLevel.debugging < Gestalt.DebugLevel.none))
	}

	@Test("Simulator detection matches build configuration")
	func simulatorDetection() {
		#if targetEnvironment(simulator)
		#expect(Gestalt.isOnSimulator == true)
		#else
		#expect(Gestalt.isOnSimulator == false)
		#endif
	}

	@Test("Extension detection")
	func extensionDetection() {
		// Should be false for test target
		#expect(Gestalt.isExtension == false)
	}

	@Test("Platform detection exclusivity")
	func platformExclusivity() {
		// At most one platform-family flag should be true.
		#if os(iOS) || os(visionOS)
		let platforms = [Gestalt.isOnMac, Gestalt.isOnWatch, Gestalt.isOnTV, Gestalt.isOnIPad, Gestalt.isOnIPhone, Gestalt.isOnVision]
		#else
		let platforms = [Gestalt.isOnMac, Gestalt.isOnWatch, Gestalt.isOnTV]
		#endif
		let trueCount = platforms.filter { $0 }.count
		#expect(trueCount <= 1)
	}

	#if os(iOS) || os(visionOS)
	@MainActor
	@Test("iOS device type detection")
	func iOSDeviceTypes() {
		let devices = [
			Gestalt.isOnIPad,
			Gestalt.isOnIPhone,
			Gestalt.isOnVision
		]
		// At least one should be true on iOS/visionOS
		let trueCount = devices.filter { $0 }.count
		#expect(trueCount >= 1)

		// iPad and iPhone should not both be true
		#expect(!(Gestalt.isOnIPad && Gestalt.isOnIPhone))
	}

	@MainActor
	@Test("Device name is not empty")
	func deviceName() {
		#expect(!Gestalt.deviceName.isEmpty)
	}

	@MainActor
	@Test("OS major version is positive")
	func osMajorVersion() {
		#expect(Gestalt.osMajorVersion > 0)
		#expect(Gestalt.osMajorVersion >= 13) // iOS 13+ minimum
	}

	@Test("Simulator info on simulator", .enabled(if: Gestalt.isOnSimulator))
	func simulatorInfo() {
		#expect(Gestalt.simulatorMachineName != nil)
		#expect(Gestalt.simulatorSystemName != nil)
		#expect(!Gestalt.simulatorInfo.isEmpty)
	}
	#endif

	@Test("UI tests flag")
	func uiTestsDetection() {
		// Should be false in unit tests
		#expect(Gestalt.isRunningUITests == false)
	}

	@Test("Build date exists")
	func buildDate() {
		#expect(Gestalt.buildDate != nil)
		if let buildDate = Gestalt.buildDate {
			// Allow a 1-minute slack for clock skew on CI machines whose clock may drift slightly.
			#expect(buildDate < Date().addingTimeInterval(60))
		}
	}

	@Test("Device ID format", .enabled(if: !Gestalt.isOnMac || Gestalt.isOnWatch))
	func deviceIDFormat() async {
		if let deviceID = await Gestalt.deviceID {
			// Should be a valid UUID string or similar
			#expect(!deviceID.isEmpty)
		}
	}

	@MainActor
	@Test("Ensure main thread works on main thread")
	func ensureMainThread() {
		// Should not assert when called from main thread
		Gestalt.ensureMainThread(message: "test")
		// Test passes if no assertion fires
	}
}
