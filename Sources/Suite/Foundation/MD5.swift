//
//  MD5.swift
//  
//
//  Created by Ben Gottlieb on 9/10/21.
//

#if canImport(CryptoKit)
import Foundation
import CryptoKit

fileprivate let emptyMD5 = "d41d8cd98f00b204e9800998ecf8427e"

public protocol MD5able {
	var md5: String { get throws }
}

@available(watchOS 6.0, iOS 13.0, macOS 10.15, *)
extension [MD5able]: MD5able {
	public var md5: String {
		get throws {
			if isEmpty { return emptyMD5 }
			let result = try compactMap { try $0.md5 }.joined(separator: "-")
			return result
		}
	}
}

enum MD5ableError: LocalizedError { case unableToConvertStringToData, unableToParseRemoteURLs
	var errorDescription: String? {
		switch self {
		case .unableToConvertStringToData: "Unable to convert string to data"
		case .unableToParseRemoteURLs: "Unable to extract MD5 from remote URLs"
		}
	}
}

@available(watchOS 6.0, iOS 13.0, macOS 10.15, *)
extension String: MD5able {
	public var md5: String {
		get throws {
			if isEmpty { return emptyMD5 }
			return try autoreleasepool {
				guard let data = data(using: .utf8) else { throw MD5ableError.unableToConvertStringToData }
				return Insecure.MD5.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
			}
		}
	}
}

@available(watchOS 6.0, iOS 13.0, macOS 10.15, *)
extension Data: MD5able {
	public var md5: String {
		get throws {
			if isEmpty { return emptyMD5 }
			return autoreleasepool {
				Insecure.MD5.hash(data: self).map { String(format: "%02hhx", $0) }.joined()
			}
		}
	 }
}

@available(watchOS 6.0, iOS 13.0, macOS 10.15, *)
extension URL: MD5able {
	public var md5: String {
		get throws {
			try autoreleasepool {
				guard isFileURL else { throw MD5ableError.unableToParseRemoteURLs }
				let data = try Data(contentsOf: self)
				return Insecure.MD5.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
			}
		}
	}
}

#endif
