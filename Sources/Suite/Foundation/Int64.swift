//
//  Int64.swift
//
//
//  Created by Ben Gottlieb on 8/28/23.
//

import Foundation

public extension Int64 {
	@MainActor static let byteFormatter = ByteCountFormatter()
	
	@MainActor var bytesString: String {
		Self.byteFormatter.string(fromByteCount: self)
	}
}


