//
//  IdentifiableEnum.swift
//
//
//  Created by Ben Gottlieb on 5/28/24.
//

import Foundation

/// `id` returns the case name only, dropping any associated values. Two enum cases with the same
/// name but different associated values share the same `id` — so this protocol is intended for
/// **enums without associated values** (or where collision is acceptable, e.g. for grouping).
/// Using `IdentifiableEnum` with `ForEach` over an array containing `.foo(1)` and `.foo(2)` will
/// break diffing.
public protocol IdentifiableEnum: Identifiable {
}

extension IdentifiableEnum {
	public var id: String {
		let raw = String(describing: self)
		return raw.components(separatedBy: "(").first ?? raw
	}
}
