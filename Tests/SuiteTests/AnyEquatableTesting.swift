//
//  Test.swift
//  Suite
//
//  Created by Ben Gottlieb on 3/1/25.
//

import Testing
import Suite

struct EquatableTests {
	
	struct TestEquatable: Equatable, Hashable {
		let a: Int
		let b: Int
	}
	
	@Test func testAnyEquatable() async throws {
		let t1 = TestEquatable(a: 1, b: 2)
		let t2 = TestEquatable(a: 1, b: 2)
		#expect(isEqual(t1, t2))
		
		let s1: Set<AnyHashable> = ["1234", 44, 1.0, t1]
		let s2: Set<AnyHashable> = ["1234", 44, 1.0, t2]
		let s3: Set<AnyHashable> = ["1234", 44, 1.01, t2]
		#expect(isEqual(s1, s2))
		#expect(!isEqual(s1, s3))

		#expect(isEqual(["a": "1234", "b": 44, "c": 1.0, "d": t1], ["a": "1234", "b": 44, "c": 1.0, "d": t1]))

		#expect(isEqual(["1234", 44, 1.0, t1], ["1234", 44, 1.0, t1]))
		#expect(!isEqual([44, 1.0, "1234"], ["1234", 44, 1.0]))
		
		#expect(isEqual("123", "123"))
		#expect(!isEqual("123", 44))
		
		let set1: Set<AnyHashable> = [44, 1.0, "1234"]
		let set2: Set<AnyHashable> = ["1234", 44, 1.0]
		#expect(isEqual(set1, set2))
	}
	
}
