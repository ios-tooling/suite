//
//  JSON+Codable.swift
//  
//
//  Created by Ben Gottlieb on 6/24/23.
//

import Testing
@testable import Suite

struct JSON_Codable {
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

    @Test func testDictionaryCoding() throws {
		 let subject = TestCodable()
		 let data = try JSONEncoder().encode(subject)
		 let _ = String(data: data, encoding: .utf8)!
		 let _ = try JSONDecoder().decode(TestCodable.self, from: data)
		 
		 #expect(!data.isEmpty)
    }
	
	struct CodingTest: Codable, Equatable {
		let dict: CodableJSONDictionary
		var val = "sdf"
	}
	
	@Test func testCodableJSONDictionary() {
		let subDict: [String: any JSONDataType] = ["1": "hello", "2a": 44, "array": [1, 2, 3, 4, 9, 8]]
		var json: [String: any JSONDataType] = ["a": 1.0, "b": "string", "c": Date().nearestSecond]
		json["d"] = subDict as? (any JSONDataType)
		
		let starter = CodableJSONDictionary(json)!
		let container = CodingTest(dict: starter, val: "hello again")
		let data = try! JSONEncoder().encode(container)
		let _ = String(data: data, encoding: .utf8)
		
		let rehydrated = try! JSONDecoder().decode(CodingTest.self, from: data)
		#expect(rehydrated == container)
	}
	


}
