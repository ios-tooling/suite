//
//  Throwable.swift
//  Suite
//
//  Created by Ben Gottlieb on 6/8/25.
//

import Foundation

public protocol Throwable: LocalizedError {
	var userFriendlyMessage: String { get }
}

extension Throwable where Self: RawRepresentable, RawValue == String {
	public var userFriendlyMessage: String {
		rawValue
	}
}

extension Throwable {
	public var errorDescription: String? {
		userFriendlyMessage
	}
}
