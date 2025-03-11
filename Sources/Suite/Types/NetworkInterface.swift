//
//  File.swift
//  Suite
//
//  Created by Ben Gottlieb on 7/10/24.
//

import Foundation

extension Gestalt {
	public static let ipv4Address: String? = { ipAddress(family: AF_INET) }()
	public static let ipv6Address: String? = { ipAddress(family: AF_INET6) }()

	static func ipAddress(family: Int32) -> String? {
		let interfaces = NetworkInterface.allInterfaces

		if let en0 = interfaces.first(where: { $0.name == "en0" && $0.family == UInt8(family) }) {
			return en0.address
		}

		if let en1 = interfaces.first(where: { $0.name == "en1" && $0.family == UInt8(family) }) {
			return en1.address
		}
		return nil
	}
	
	public static let IPAddress: String? = { ipv4Address ?? ipv6Address }()
}

public struct NetworkInterface: CustomStringConvertible, Sendable {
	public let address: String
	public let name: String
	public let family: UInt8
	
	public var description: String {
		"\(name): \(family) \(address)"
	}
	
	
	public static var allInterfaces: [NetworkInterface] {
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
					
					//let address: String = String(decoding: hostname, as: UTF8.self)
					let address = String(NSString(cString: hostname, encoding: NSUTF8StringEncoding) ?? "")
					//let address = String(cString: hostname)
					if !address.isEmpty {
						results.append(.init(address: address, name: String(cString: cString), family: addrFamily))
					}
				}
			}
			freeifaddrs(ifaddr)
		}
		return results
	}
}
