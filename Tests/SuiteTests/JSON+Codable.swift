//
//  JSON+Codable.swift
//  
//
//  Created by Ben Gottlieb on 6/24/23.
//

import XCTest
@testable import Suite

final class JSON_Codable: XCTestCase {
	struct TestCodable: Codable {
		enum CodingKeys: String, CodingKey { case json }
		var json: [String: Any] = ["kind": "Old friend", "count": 14, "nested": ["n1": "a", "n2": "b"], "items": [1, 3, 5, 7, 9, 3], "date": Date()]

		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			
			try container.encode(json, forKey: .json)
		}

		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			json = try container.decode([String: Any].self, forKey: .json)
		}
		
		init() { }
	}

    func testDictionaryCoding() throws {
		 let subject = TestCodable()
		 let data = try JSONEncoder().encode(subject)
		 let string = String(data: data, encoding: .utf8)!
		 let decoded = try JSONDecoder().decode(TestCodable.self, from: data)
		 
//		 dlogg(string)
//		 dlogg(decoded)
		 
		 XCTAssert(!data.isEmpty, "Shouldn't encode empty data")
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
	
	struct CodingTest: Codable, Equatable {
		let dict: CodableJSONDictionary
		var val = "sdf"
	}
	
	func testCodableJSONDictionary() {
		let subDict: [String: any JSONDataType] = ["1": "hello", "2a": 44, "array": [1, 2, 3, 4, 9, 8]]
		var json: [String: any JSONDataType] = ["a": 1.0, "b": "string", "c": Date().nearestSecond]
		json["d"] = subDict as? (any JSONDataType)
		
		let starter = CodableJSONDictionary(json)!
		let container = CodingTest(dict: starter, val: "hello again")
		let data = try! JSONEncoder().encode(container)
		let string = String(data: data, encoding: .utf8)
		
		let rehydrated = try! JSONDecoder().decode(CodingTest.self, from: data)
		XCTAssert(rehydrated == container, "Decoded struct should match original.")
	}
	


}
