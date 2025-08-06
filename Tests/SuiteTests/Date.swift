//
//  Date.swift
//  
//
//  Created by Ben Gottlieb on 2/18/23.
//

import Testing
import Suite


struct DateTests {
	
	@Test func testTimeRangeIntersections() {
		let start = Date.TimeRange(.init(hour: 9, minute: 30), .init(hour: 11, minute: 30))
		let end = Date.TimeRange(.init(hour: 10, minute: 0), .init(hour: 13, minute: 0))
		let otherEnd = Date.TimeRange(.init(hour: 16, minute: 0), .init(hour: 17, minute: 0))

		let intersection = start.intersection(with: end)
		#expect(intersection == Date.TimeRange(.init(hour: 10, minute: 0), .init(hour: 11, minute: 30)))

		let badIntersection = start.intersection(with: otherEnd)
		#expect(badIntersection == nil)
	}

    @Test func testDateRawValue() throws {
		 let date = Date()
		 let raw = date.rawValue
		 let newDate = Date(rawValue: raw)
		 
		 #expect(newDate == date)
	 }
}
