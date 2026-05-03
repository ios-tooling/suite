//
//  Pluralizer.swift
//
//
//  Created by Ben Gottlieb on 12/18/20.
//

import Foundation


public final class Pluralizer: @unchecked Sendable {
	public static let instance = Pluralizer()

	private let lock = NSLock()
	private var plurals: [String: String] = [:]

	private init() {}

	public func pluralize(_ count: Int, _ singular: String, spelledOut: Bool = false) -> String {
		if count == 1 { return "1 " + singular }
		return "\(count) \(self[singular])"
	}

	public subscript(singular: String) -> String {
		get {
			let key = singular.lowercased()
			lock.lock()
			defer { lock.unlock() }
			if let plural = plurals[key] { return plural }
			return singular.hasSuffix("s") ? singular : singular + "s"
		}
		set {
			let key = singular.lowercased()
			lock.lock()
			defer { lock.unlock() }
			plurals[key] = newValue
		}
	}
}
