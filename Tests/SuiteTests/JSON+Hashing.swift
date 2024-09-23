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
		 let testJSON1 = "{  \"a\" : 1,  \"b\" : 2,  \"c\" : 3}"
		 let testJSON2 = "{  \"a\" : 1,  \"b\" : 2,  \"c\" : 3}"

		 let testStruct = TestCodable()
		 print(testStruct.prettyJSON)
		 let testDict3: JSONDictionary = try testJSON1.asJSON()
//		 let testDict1 = try testStruct.asJSONData().asJSON()
//		 let testDict2 = try testStruct.asJSONData().asJSON()
		 
//		 let testDict2: JSONDictionary = try testJSON2.asJSON()
//		 let testHash1 = testDict1.stableMD5
//		 let testHash2 = testDict2.stableMD5

		 #expect(testStruct.stableMD5() == testDict3.stableMD5)
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}
