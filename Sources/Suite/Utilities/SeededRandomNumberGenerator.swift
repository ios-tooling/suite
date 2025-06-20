//
//  SeededRandomNumberGenerator.swift
//  
//
//  Created by Ben Gottlieb on 9/18/20.
//

import Foundation
import GameKit

#if !os(watchOS)

public struct SeededRandomNumberGenerator: RandomNumberGenerator {
	private let mersenne: GKMersenneTwisterRandomSource

	public mutating func next() -> UInt64 {
		let next1 = UInt64(bitPattern: Int64(mersenne.nextInt()))
		let next2 = UInt64(bitPattern: Int64(mersenne.nextInt()))
		return next1 ^ (next2 << 32)
	}
	
	public init(seed: Int = Int(Date().timeIntervalSinceReferenceDate)) {
		if seed == 0 { print("Seeding a zero generator") }
		self.mersenne = GKMersenneTwisterRandomSource(seed: UInt64(seed))
	}
	
	public var isZeroGenerator: Bool {
		mersenne.seed == 0
	}
}

#endif
