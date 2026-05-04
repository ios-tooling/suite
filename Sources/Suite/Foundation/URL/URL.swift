//
//  URL.swift
//
//
//  Created by Ben Gottlieb on 12/30/19.
//

import Foundation

#if os(iOS) || os(visionOS)
import UIKit

extension URL {
	@MainActor static var application: UIApplication?

	@MainActor public static func setApplication(_ app: UIApplication) { application = app }

	@MainActor public func open() {
		Self.application?.open(self)
	}
}
#endif

#if os(macOS)
import AppKit

extension URL {
	public func open() {
		NSWorkspace.shared.open(self)
	}
}
#endif

public protocol URLLocatable {
	var url: URL { get }
}

extension URL: @retroactive Identifiable {
	public var id: String { self.absoluteString }
}

extension URL: @retroactive ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self.init(string: value)!
	}
}

public extension URL {
	static let blank: URL = URL(string: "about:blank")!
	static let bundleScheme = "bundle"

	static func +(lhs: URL, rhs: String) -> URL {
		lhs.appendingPathComponent(rhs)
	}

	func dropLast() -> URL {
		deletingLastPathComponent()
	}

	init(_ string: StaticString) {
		self = URL(string: "\(string)")!
	}

	init(withPathRelativeToHome path: String) {
		self.init(fileURLWithPath: path.expandingTildeInPath)
	}

	var isAppStoreURL: Bool {
		host?.contains("apps.apple.com") == true
	}

	var filename: String { deletingPathExtension().lastPathComponent }
}
