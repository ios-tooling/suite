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
	public static var debugLevel = Gestalt.isAttachedToDebugger ? DebugLevel.debugging : DebugLevel.none
	
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
	public static let deviceID: String? = {
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
		public static let isOnVision: Bool = {
			if #available(iOS 17.0, *) {
				UIDevice.current.userInterfaceIdiom == .vision
			} else {
				false
			}
		}()
	
		static public var sleepDisabled: Bool {
			get { UIApplication.shared.isIdleTimerDisabled }
			set { UIApplication.shared.isIdleTimerDisabled = newValue }
		}
		static public let deviceName: String = UIDevice.current.name
		#if targetEnvironment(macCatalyst)
			public static let isOnMac = true
		#else
			public static let isOnMac = false
		#endif
		public static let isOnIPad: Bool = { return UIDevice.current.userInterfaceIdiom == .pad }()
		public static let isOnIPhone: Bool = { return UIDevice.current.userInterfaceIdiom == .phone }()
    
		public static let osMajorVersion: Int = {
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
	
	#if os(iOS) || os(watchOS) || os(visionOS)
		public static let simulatedRawDeviceType: String? = {
			#if targetEnvironment(simulator)
					return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
			#else
					return nil
			#endif
		}()
	
		public static let rawDeviceType: String = {
			var			systemInfo = utsname()
			uname(&systemInfo)
			let machineMirror = Mirror(reflecting: systemInfo.machine)
			let identifier = machineMirror.children.reduce("") { identifier, element in
				guard let value = element.value as? Int8 , value != 0 else { return identifier }
				return identifier + String(UnicodeScalar(UInt8(value)))
			}
			return identifier
		}()
	
		public static let modelName: String = {
			#if targetEnvironment(simulator)
				convertRawDeviceTypeToModelName(simulatedRawDeviceType ?? rawDeviceType) ?? "unknown"
			#else
				convertRawDeviceTypeToModelName(rawDeviceType) ?? "unknown"
			#endif
		}()
	
		public static func convertRawDeviceTypeToModelName(_ raw: String) -> String? {
			switch raw {
			case "iPod5,1":                           return "iPod Touch 5"
			case "iPod7,1":                           return "iPod Touch 6"
			case "iPod8,1":                           return "iPod Touch 7"
			case "iPod9,1":									return "iPod Touch 7"
				
			case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
			case "iPhone4,1":                         return "iPhone 4s"
			case "iPhone5,1", "iPhone5,2":            return "iPhone 5"
			case "iPhone5,3", "iPhone5,4":            return "iPhone 5c"
			case "iPhone6,1", "iPhone6,2":            return "iPhone 5s"
			case "iPhone7,2":                         return "iPhone 6"
			case "iPhone7,1":                         return "iPhone 6 Plus"
			case "iPhone8,1":                         return "iPhone 6s"
			case "iPhone8,2":                         return "iPhone 6s Plus"
			case "iPhone9,1", "iPhone9,3":            return "iPhone 7"
			case "iPhone9,2", "iPhone9,4":				return "iPhone 7 Plus"
			case "iPhone8,4":									return "iPhone SE"
			case "iPhone10,1", "iPhone10,4":				return "iPhone 8"
			case "iPhone10,2", "iPhone10,5":				return "iPhone 8 Plus"
			case "iPhone10,3", "iPhone10,6":				return "iPhone X"
			case "iPhone11,8":								return "iPhone Xr"
			case "iPhone11,2":								return "iPhone Xs"
			case "iPhone11,4", "iPhone11,6":				return "iPhone Xs max"

			case "iPhone12,1":								return "iPhone 11"
			case "iPhone12,3":								return "iPhone 11 Pro"
			case "iPhone12,5":								return "iPhone 11 Pro max"
			case "iPhone12,8":								return "iPhone SE 2nd gen"

			case "iPhone13,1":								return "iPhone 12 mini"
			case "iPhone13,2":								return "iPhone 12"
			case "iPhone13,3":								return "iPhone 12 Pro"
			case "iPhone13,4":								return "iPhone 12 Pro max"

			case "iPhone14,2":								return "iPhone 13 Pro"
			case "iPhone14,3":								return "iPhone 13 Pro Max"
			case "iPhone14,4":								return "iPhone 13 Mini"
			case "iPhone14,5":								return "iPhone 13"
			case "iPhone14,6":								return "iPhone SE 3rd Gen"
			case "iPhone14,7":								return "iPhone 14"
			case "iPhone14,8":								return "iPhone 14 Plus"
			case "iPhone15,2":								return "iPhone 14 Pro"
			case "iPhone15,3":								return "iPhone 14 Pro max"

			case "iPad2,5", "iPad2,6", "iPad2,7":     return "iPad Mini"
			case "iPad4,4", "iPad4,5", "iPad4,6":     return "iPad Mini 2"
			case "iPad4,7", "iPad4,8", "iPad4,9":     return "iPad Mini 3"
			case "iPad5,1", "iPad5,2":                return "iPad Mini 4"
			case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":
																	return "iPad 2"
			case "iPad3,1", "iPad3,2", "iPad3,3":     return "iPad 3"
			case "iPad3,4", "iPad3,5", "iPad3,6":     return "iPad 4"
			case "iPad4,1", "iPad4,2", "iPad4,3":     return "iPad Air"
			case "iPad5,3", "iPad5,4":                return "iPad Air 2"
			case "iPad6,4":									return "iPad Pro 9.7 in."
			case "iPad6,7", "iPad6,8":                return "iPad Pro 12.9 in."
			case "iPad7,4":									return "iPad Pro 10.5 in."
			case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":
																	return "iPad Pro 11 in."
			case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":
																	return "iPad Pro 12.9 in."
			case "iPad8,10":									return "iPad Pro 11 in. 4th gen"
			case "iPad8,11", "iPad8,12":					return "iPad Pro 12.9 in. 4th gen"
			case "iPad11,3", "iPad11,4": 					return "iPad Air 3"
			case "iPad11,1", "iPad11,2": 					return "iPad mini 5"
			case "iPad11,6", "iPad11,7": 					return "iPad 8th gen"
			case "iPad13,1", "iPad13,2": 					return "iPad air 4th gen"

			case "Watch1,1": 									return "Apple Watch Series 0 38mm"
			case "Watch1,2": 									return "Apple Watch Series 0 42mm"
			case "Watch2,6": 									return "Apple Watch Series 1 38mm"
			case "Watch2,7": 									return "Apple Watch Series 1 42mm"
			case "Watch2,3": 									return "Apple Watch Series 2 38mm"
			case "Watch2,4": 									return "Apple Watch Series 2 42mm"
			case "Watch3,1", "Watch3,3": 					return "Apple Watch Series 3 38mm"
			case "Watch3,2", "Watch3,4": 					return "Apple Watch Series 3 42mm"
			case "Watch4,1", "Watch4,3": 					return "Apple Watch Series 4 40mm"
			case "Watch4,2", "Watch4,4": 					return "Apple Watch Series 4 44mm"
			case "Watch5,1", "Watch5,3": 					return "Apple Watch Series 5 40mm"
			case "Watch5,2", "Watch5,4": 					return "Apple Watch Series 5 44mm"

			case "Watch5,9", "Watch5,11":					return "Apple Watch SE 40mm"
			case "Watch5,10", "Watch5,12":				return "Apple Watch SE 44mm"

			case "Watch6,1", "Watch6,3": 					return "Apple Watch Series 6 40mm"
			case "Watch6,2", "Watch6,4": 					return "Apple Watch Series 6 44mm"
			case "Watch6,6", "Watch6,8": 					return "Apple Watch Series 7 41mm"
			case "Watch6,7", "Watch6,9": 					return "Apple Watch Series 7 45mm"

			case "AppleTV1,1": 								return "Apple TV 1st gen"
			case "AppleTV2,1": 								return "Apple TV 2nd gen"
			case "AppleTV3,1": 								return "Apple TV 3rd gen"
			case "AppleTV3,2": 								return "Apple TV 3rd gen"
			case "AppleTV5,3": 								return "Apple TV HD 4th gen"
			case "AppleTV6,2": 								return "Apple TV 4K"

			case "RealityDevice14,1": 						return "Apple Vision Pro"
			default: return nil
			}
		}
	
//		public static var deviceType: String = {
//			let raw = Gestalt.rawDeviceType
//			switch raw {
//			case "i386", "x86_64":
//				let screenSize = UIScreen.main.bounds.size
//				let size = (Int(screenSize.width), Int(screenSize.height))
//				let scale = Int(UIView.screenScale)
//
//				switch size {
//				case (320, 480): return "Simulator, iPhone 4"
//				case (320, 568):
//					return "Simulator, iPhone 5" + (raw == "x86_64" ? "s" : "")
//				case (375, 667): return "Simulator, iPhone 7"
//				case (414, 736): return "Simulator, iPhone 7+"
//				case (768, 1024):
//					if raw == "x86_64" { return "Simulator, iPad air" }
//					return "Simulator, iPad " + (scale == 1 ? "2" : "4")
//				case (1024, 1366): return "Simulator, iPad Pro"
//				default: return "Simulator, \(size.0)x\(size.1) @\(scale)x"
//				}
//
//
//			default: return Gestalt.convertRawDeviceTypeToModelName(raw) ?? raw
//			}
//		}()
	
		public static let isRunningUITests: Bool = {
			return ProcessInfo.processInfo.arguments.contains("-ui_testing")
		}()
	
	
	#else
		#if os(macOS)
			static public var sleepDisabled: Bool {
				get { NSApp.sleepDisabled }
				set { NSApp.sleepDisabled = newValue }
			}
			public static let serialNumber: String? = {
				let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
				
				let string = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue()
				return string as? String
			}()
		#endif
	
	#endif
	
	public static let isRunningUnitTests: Bool = {
		return NSClassFromString("XCTest") != nil
	}()
	
	public static let ipv4Address: String? = { ipAddress(family: AF_INET) }()
	public static let ipv6Address: String? = { ipAddress(family: AF_INET6) }()

	
	static func ipAddress(family: Int32) -> String? {
		let interfaces = allInterfaces

		if let en0 = interfaces.first(where: { $0.name == "en0" && $0.family == UInt8(family) }) {
			return en0.address
		}

		if let en1 = interfaces.first(where: { $0.name == "en1" && $0.family == UInt8(family) }) {
			return en1.address
		}
		return nil
	}
	
	public static let IPAddress: String? = { ipv4Address ?? ipv6Address }()
	
	struct NetworkInterface: CustomStringConvertible {
		let address: String
		let name: String
		let family: UInt8
		
		var description: String {
			"\(name): \(family) \(address)"
		}
	}
	
	static var allInterfaces: [NetworkInterface] {
		var results: [NetworkInterface] = []
		
		var ifaddr: UnsafeMutablePointer<ifaddrs>?
		if getifaddrs(&ifaddr) == 0 {
			var ptr = ifaddr
			while ptr != nil {
				defer { ptr = ptr?.pointee.ifa_next }
				let interface = ptr?.pointee
				
				guard let addrFamily = interface?.ifa_addr.pointee.sa_family else { continue }
				guard let cString = interface?.ifa_name else { continue }
				
				if let saLen = (interface?.ifa_addr.pointee.sa_len) {
					var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
					let ifaAddr = interface?.ifa_addr
					getnameinfo(ifaAddr, socklen_t(saLen), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
					
					let address = String(cString: hostname)
					if !address.isEmpty {
						results.append(.init(address: address, name: String(cString: cString), family: addrFamily))
					}
				}
			}
			freeifaddrs(ifaddr)
		}
		return results
	}
	
	public static let buildDate: Date? = { Bundle.main.executableURL?.createdAt }()
}
