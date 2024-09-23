//
//  Test.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/23/24.
//

import Testing
import Suite

struct Test {

    @Test func testStableMD5() async throws {
		 let testJSON1 =
"""
{
	"a": 1,
	"b": 2,
	"c": 3
}
"""

		 let testJSON2 =
"""
{
 "c": 3
 "b": 2,
 "a": 1,
}
"""
		 
		 let testDict1: JSONDictionary = try testJSON1.asJSON()
		 let testDict2: JSONDictionary = try testJSON2.asJSON()
		 
		 #expect(testDict1.stableMD5() == testDict2.stableMD5())
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}
