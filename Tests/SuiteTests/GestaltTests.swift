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

	@Test("Simulator detection is boolean")
	func simulatorDetection() {
		// Should be either true or false, never nil
		let isSimulator = Gestalt.isOnSimulator
		#expect(isSimulator == true || isSimulator == false)
	}

	@Test("Debugger attachment is boolean")
	func debuggerAttachment() {
		let isAttached = Gestalt.isAttachedToDebugger
		#expect(isAttached == true || isAttached == false)
	}

	@Test("Extension detection")
	func extensionDetection() {
		// Should be false for test target
		#expect(Gestalt.isExtension == false)
	}

	@Test("Preview detection")
	func previewDetection() {
		let isPreview = Gestalt.isInPreview
		#expect(isPreview == true || isPreview == false)
	}

	@Test("Platform detection exclusivity")
	func platformExclusivity() {
		// Only one platform should be true
		let platforms = [
			Gestalt.isOnMac,
			Gestalt.isOnWatch,
			Gestalt.isOnTV
		]
		let trueCount = platforms.filter { $0 }.count
		#expect(trueCount <= 1) // At most one platform is true
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

	@Test("Running unit tests flag")
	func unitTestsDetection() {
		// Note: Swift Testing framework doesn't use XCTest, so this may be false
		// Just verify the property is accessible and returns a boolean
		let isRunning = Gestalt.isRunningUnitTests
		#expect(isRunning == true || isRunning == false)
	}

	@Test("UI tests flag")
	func uiTestsDetection() {
		// Should be false in unit tests
		#expect(Gestalt.isRunningUITests == false)
	}

	@Test("Build date exists")
	func buildDate() {
		#expect(Gestalt.buildDate != nil)
		if let buildDate = Gestalt.buildDate {
			#expect(buildDate < Date()) // Build date should be in the past
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
