//
//  SeededRandomNumberGenerator.swift
//  
//
//  Created by Ben Gottlieb on 9/18/20.
//

import Foundation
import GameKit

#if !os(watchOS)

extension GKMersenneTwisterRandomSource: @retroactive @unchecked Sendable { }

public struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
	private let mersenne: GKMersenneTwisterRandomSource
	
	static let queue = DispatchSerialQueue.global()
	nonisolated(unsafe) private static var sharedGenerator = SeededRandomNumberGenerator()
	
	public nonisolated static func reseed(seed: Int) {
		queue.sync {
			sharedGenerator = SeededRandomNumberGenerator(seed: seed)
		}
	}
	
	public nonisolated static func reseed(seed: UInt64) {
		reseed(seed: Int(seed))
	}
	
	public nonisolated static func next() -> UInt64 {
		queue.sync {
			sharedGenerator.next()
		}
	}
	
	private nonisolated static var anyRNG: any RandomNumberGenerator {
		get { sharedGenerator }
		set {
			if let rng = newValue as? SeededRandomNumberGenerator {
				sharedGenerator = rng
			}
		}
	}

	public nonisolated static func with<T>(_ block: (inout any RandomNumberGenerator) -> T) -> T {
		queue.sync {
			block(&anyRNG)
		}
	}

	public mutating func next() -> UInt64 {
		let next1 = UInt64(bitPattern: Int64(mersenne.nextInt()))
		let next2 = UInt64(bitPattern: Int64(mersenne.nextInt()))
		return next1 ^ (next2 << 32)
	}
	
	public init(seed: Int = Int(Date().timeIntervalSinceReferenceDate)) {
		if seed == 0 { print("Seeding a zero generator") }
		self.mersenne = GKMersenneTwisterRandomSource(seed: UInt64(seed))
	}
	
	public init(seed: UInt64) {
		if seed == 0 { print("Seeding a zero generator") }
		self.mersenne = GKMersenneTwisterRandomSource(seed: seed)
	}
	
	public var isZeroGenerator: Bool {
		mersenne.seed == 0
	}
}

#endif
