//
//  Test.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/23/24.
//

import Testing
import Suite

struct TestCodable: Codable {
	var a = 1
	var b = 2
	var c = 3
}

struct Test {

    @Test func testStableMD5() async throws {
		 let testJSON1 = "{  \"a\" : 1,  \"b\" : 2,  \"c\" : 3 }"
		 let testJSON2 = "{  \"a\" : 1,  \"c\" : 3,  \"b\" : 2 }"

		 let testStruct = TestCodable()
		 
		 let testDict1 = testJSON1.data(using: .utf8)!.jsonDictionary!
		 let testDict2 = testJSON2.data(using: .utf8)!.jsonDictionary!
//		 let testDict3 = try testStruct.asJSON()
		 let testHash1 = testDict1.stableMD5
		 let testHash2 = testDict2.stableMD5
		 let testHash3 = testStruct.stableMD5()

		 #expect(testHash1 == testHash3)
		 #expect(testHash1 == testHash2)
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}
