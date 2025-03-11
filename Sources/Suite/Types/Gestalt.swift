//
//  MobileProvisionFile.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/9/19.
//  Copyright © 2017 Stand Alone, Inc. All rights reserved.
//

import Foundation

#if os(iOS) || os(visionOS)
	import UIKit
#endif

#if os(macOS)
	import Cocoa
#endif

#if os(watchOS)
	import WatchKit
#endif


public struct Gestalt {
	public enum Distribution: Sendable { case development, testflight, appStore }
	
	
	public static let distribution: Distribution = {
		#if DEBUG
			return .development
		#else
			#if os(OSX)
				let bundlePath = Bundle.main.bundleURL
				let receiptURL = bundlePath.appendingPathComponent("Contents").appendingPathComponent("_MASReceipt").appendingPathComponent("receipt")
				
				return FileManager.default.fileExists(at: receiptURL) ? .appStore : .development
			#else
				if isOnSimulator { return .development }
				if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
					//if MobileProvisionFile.default?.properties["ProvisionedDevices"] == nil
					return .testflight
				}
				
				return .appStore
			#endif
		#endif
	}()

	public enum DebugLevel: Int, Comparable, Sendable { case none, testFlight, internalTesting, debugging
		public static func < (lhs: Gestalt.DebugLevel, rhs: Gestalt.DebugLevel) -> Bool { return lhs.rawValue < rhs.rawValue }
	}
	nonisolated(unsafe) public static var debugLevel = Gestalt.isAttachedToDebugger ? DebugLevel.debugging : DebugLevel.none
	
	#if targetEnvironment(simulator)
		public static let isOnSimulator: Bool = true
	#else
		public static let isOnSimulator: Bool = false
	#endif
	
	public static let isAttachedToDebugger: Bool = { return isatty(STDERR_FILENO) != 0 }()
	
	public static func ensureMainThread(message: String? = nil) {
		assert(Thread.isMainThread, "must run on main thread \(message ?? "--")!")
	}
	
	public static let isExtension: Bool = {
		let extensionDictionary = Bundle.main.infoDictionary?["NSExtension"]
		return extensionDictionary is NSDictionary
	}()
	
	public static let isInPreview: Bool = { ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }()
	@MainActor public static let deviceID: String? = {
		#if os(watchOS)
			if #available(watchOS 6.2, *) {
				return WKInterfaceDevice.current().identifierForVendor?.uuidString
			} else {
				return nil
			}
		#elseif os(iOS) || os(visionOS)
			return UIDevice.current.identifierForVendor?.uuidString
		#elseif  os(macOS)
			return serialNumber
		#endif
	}()
	
	#if os(OSX)
		public static let isOnMac: Bool = true
		
		public static let rawDeviceType: String = {
			let service: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
			let cfstr = "model" as CFString
			if let model = IORegistryEntryCreateCFProperty(service, cfstr, kCFAllocatorDefault, 0).takeUnretainedValue() as? Data {
			  if let nsstr =  String(data: model, encoding: .utf8) {
					  return nsstr
				 }
			}
			return ""
	}()
	
	static public let deviceName: String = { rawDeviceType }()
	#endif
	
	#if os(macOS)
		public static let isOnIPad = false
		public static let isOnIPhone = false
		public static let isOnVision = false
	#endif
	
	#if os(watchOS)
		public static let isOnWatch = true
		public static let isOnIPad = false
		public static let isOnIPhone = false
		public static let isOnVision = false
	#else
		public static let isOnWatch = false
	#endif
	
	#if os(tvOS)
		public static let isOnTV = true
		public static let isOnVision = false
	#else
		public static let isOnTV = false
	#endif

	
	#if os(iOS) || os(visionOS)
		@MainActor public static let isOnVision: Bool = {
			if #available(iOS 17.0, *) {
				UIDevice.current.userInterfaceIdiom == .vision
			} else {
				false
			}
		}()
	
		@MainActor static public var sleepDisabled: Bool {
			get { UIApplication.shared.isIdleTimerDisabled }
			set { UIApplication.shared.isIdleTimerDisabled = newValue }
		}
	@MainActor static public let deviceName: String = UIDevice.current.name
		#if targetEnvironment(macCatalyst)
			public static let isOnMac = true
		#else
			public static let isOnMac = false
		#endif
		@MainActor public static let isOnIPad: Bool = { return UIDevice.current.userInterfaceIdiom == .pad }()
		@MainActor public static let isOnIPhone: Bool = { return UIDevice.current.userInterfaceIdiom == .phone }()
    
		@MainActor public static let osMajorVersion: Int = {
			return Int(UIDevice.current.systemVersion.components(separatedBy: ".").first ?? "") ?? 0
		}()
	
		enum SimulatorHostInfo: Int, CaseIterable, Sendable { case sysname = 0, nodename, release, version, machine }
		static func getSimulatorHostInfo(which: SimulatorHostInfo) -> String? {
			let structSize = MemoryLayout<utsname>.size
			let fieldSize = structSize / SimulatorHostInfo.allCases.count
			var systemInfo = [UInt8](repeating: 0, count: structSize)
			
			let info = systemInfo.withUnsafeMutableBufferPointer { ( body: inout UnsafeMutableBufferPointer<UInt8>) -> String? in
				var valid = false
				guard let base = body.baseAddress else { return nil }
				base.withMemoryRebound(to: utsname.self, capacity: 1) { data in
					valid = uname(data) == 0
				}

				if !valid { return nil }

				let all = Array(body)
				let offset = which.rawValue * fieldSize
				let chunk = Array(all[offset..<(offset + fieldSize)])
				let count = chunk.firstIndex(where: { $0 == 0 }) ?? fieldSize
				return String(bytes: chunk[0..<count], encoding: .utf8)
			}
			return info
		}
		public static let simulatorMachineName: String? = { Gestalt.getSimulatorHostInfo(which: .nodename) }()
		public static let simulatorSystemName: String? = { Gestalt.getSimulatorHostInfo(which: .sysname) }()
		public static let simulatorReleaseName: String? = { Gestalt.getSimulatorHostInfo(which: .release) }()
		public static let simulatorVersionName: String? = { Gestalt.getSimulatorHostInfo(which: .version) }()
		public static let simulatorCPUName: String? = { Gestalt.getSimulatorHostInfo(which: .machine) }()

		public static let simulatorInfo: String = {
			SimulatorHostInfo.allCases.map { getSimulatorHostInfo(which: $0) }.compactMap { $0 }.joined(separator: "- ")
		}()

	#endif
	
	public static let isRunningUITests: Bool = {
		return ProcessInfo.processInfo.arguments.contains("-ui_testing")
	}()
	
	#if os(macOS)
		@MainActor static public var sleepDisabled: Bool {
			get { NSApp.sleepDisabled }
			set { NSApp.sleepDisabled = newValue }
		}
		public static let serialNumber: String? = {
			let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
			
			let string = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue()
			return string as? String
		}()
	#endif

	public static let isRunningUnitTests: Bool = {
		return NSClassFromString("XCTest") != nil
	}()

	public static let buildDate: Date? = { Bundle.main.executableURL?.createdAt }()
}
