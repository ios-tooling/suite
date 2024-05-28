//
//  IdentifiableEnum.swift
//
//
//  Created by Ben Gottlieb on 5/28/24.
//

import Foundation

public protocol IdentifiableEnum: Identifiable {
}

extension IdentifiableEnum {
	public var id: String {
		let raw = String(describing: self)
		return raw.components(separatedBy: "(").first ?? raw
	}
}
