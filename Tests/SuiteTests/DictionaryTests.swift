//
//  DictionaryTests.swift
//  
//
//  Created by Ben Gottlieb on 3/5/23.
//

import Testing
import Suite

struct DictionaryTests {

    @Test func testDictionaryDiff() throws {
		 let dict1: [String: Any] = ["A": 1, "B": "c", "C": ["1": 3]]
		 let dict2: [String: Any] = ["A": 1, "B": "c", "C": ["1": 3]]
		 let dict3: [String: Any] = ["A": "1", "B": "c", "C": ["1", 3]]
		 let dict4: [String: Any] = ["A": 1, "B": "c", "C": ["1": "a"], "D": 4]

		 let diff1To2 = dict1.diff(relativeTo: dict2)
		 let diff1To3 = dict1.diff(relativeTo: dict3)
		 let diff1To4 = dict1.diff(relativeTo: dict4)

		 #expect(diff1To2.isEmpty)
		 #expect(diff1To3.count == 2)
		 #expect(diff1To4.count == 2)
    }
}
