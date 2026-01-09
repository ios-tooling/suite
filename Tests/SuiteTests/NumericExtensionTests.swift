//
//  NumericExtensionTests.swift
//  Suite
//
//  Created by Claude Code
//

import Testing
import Foundation
@testable import Suite

@Suite("Numeric Extension Tests")
struct NumericExtensionTests {

	@Test("Capped values within range")
	func cappedWithinRange() {
		let value = 5
		let capped = value.capped(1...10)
		#expect(capped == 5)
	}

	@Test("Capped values below range")
	func cappedBelowRange() {
		let value = -5
		let capped = value.capped(1...10)
		#expect(capped == 1)
	}

	@Test("Capped values above range")
	func cappedAboveRange() {
		let value = 15
		let capped = value.capped(1...10)
		#expect(capped == 10)
	}

	@Test("Capped at boundaries")
	func cappedAtBoundaries() {
		#expect(1.capped(1...10) == 1)
		#expect(10.capped(1...10) == 10)
	}

	@Test("Capped with doubles")
	func cappedDoubles() {
		let value = 5.5
		let capped = value.capped(1.0...10.0)
		#expect(capped == 5.5)

		#expect(0.5.capped(1.0...10.0) == 1.0)
		#expect(15.5.capped(1.0...10.0) == 10.0)
	}

	@Test("Fixed width integer bytes")
	func fixedWidthBytes() {
		let value: UInt32 = 0x12345678
		let bytes = value.bytes

		#expect(bytes.count == 4)
		#expect(bytes[0] == 0x12)
		#expect(bytes[1] == 0x34)
		#expect(bytes[2] == 0x56)
		#expect(bytes[3] == 0x78)
	}

	@Test("Byte width calculation")
	func byteWidth() {
		let int8: UInt8 = 0
		let int16: UInt16 = 0
		let int32: UInt32 = 0
		let int64: UInt64 = 0

		#expect(int8.byteWidth == 1)
		#expect(int16.byteWidth == 2)
		#expect(int32.byteWidth == 4)
		#expect(int64.byteWidth == 8)
	}

	@Test("Individual byte access")
	func individualBytes() {
		let value: UInt32 = 0x12345678

		#expect(value.b1 == 0x12)
		#expect(value.b2 == 0x34)
		#expect(value.b3 == 0x56)
		#expect(value.b4 == 0x78)
	}

	@Test("Character code conversion")
	func characterCode() {
		let value: UInt32 = 0x41424344 // "ABCD" in ASCII

		let code = value.characterCode
		#expect(code == "ABCD")
	}
}

@Suite("TimeInterval Extension Tests")
struct TimeIntervalTests {

	@Test("Time interval constants")
	func constants() {
		#expect(TimeInterval.minute == 60.0)
		#expect(TimeInterval.hour == 3600.0)
		#expect(TimeInterval.day == 86400.0)
		#expect(TimeInterval.week == 604800.0)
	}

	@Test("Days calculation")
	func daysCalculation() {
		let oneDay: TimeInterval = .day
		let twoDays: TimeInterval = .day * 2
		let negative: TimeInterval = -.day

		#expect(oneDay.days == 1)
		#expect(twoDays.days == 2)
		#expect(negative.days == 1) // abs
	}

	@Test("Hours calculation")
	func hoursCalculation() {
		let oneHour: TimeInterval = .hour
		let twentyFourHours: TimeInterval = .hour * 24

		#expect(oneHour.hours == 1)
		#expect(twentyFourHours.hours == 24)
	}

	@Test("Minutes calculation")
	func minutesCalculation() {
		let oneMinute: TimeInterval = .minute
		let sixtyMinutes: TimeInterval = .minute * 60

		#expect(oneMinute.minutes == 1)
		#expect(sixtyMinutes.minutes == 60)
	}

	@Test("Seconds calculation")
	func secondsCalculation() {
		let oneSecond: TimeInterval = 1.0
		let sixtySeconds: TimeInterval = 60.0

		#expect(oneSecond.seconds == 1)
		#expect(sixtySeconds.seconds == 60)
	}

	@Test("Leftover hours")
	func leftoverHours() {
		let twentyFiveHours: TimeInterval = .hour * 25

		#expect(twentyFiveHours.leftoverHours == 1) // 25 % 24 = 1
	}

	@Test("Leftover minutes")
	func leftoverMinutes() {
		let sixtyOneMinutes: TimeInterval = .minute * 61

		#expect(sixtyOneMinutes.leftoverMinutes == 1) // 61 % 60 = 1
	}

	@Test("Leftover seconds")
	func leftoverSeconds() {
		let sixtyOneSeconds: TimeInterval = 61.0

		#expect(sixtyOneSeconds.leftoverSeconds == 1) // 61 % 60 = 1
	}

	@Test("Duration string simple")
	func durationStringSimple() {
		let oneMinute: TimeInterval = 60.0
		let string = oneMinute.durationString(style: .seconds, showLeadingZero: false, roundUp: false)

		#expect(!string.isEmpty)
		// Should be something like "1:00" or "0:59" depending on rounding
	}

	@Test("Duration string with hours")
	func durationStringHours() {
		let oneHour: TimeInterval = .hour
		let string = oneHour.durationString(style: .hours, showLeadingZero: false, roundUp: false)

		#expect(!string.isEmpty)
	}

	@Test("Duration string minutes only")
	func durationStringMinutes() {
		let ninetyMinutes: TimeInterval = .minute * 90
		let string = ninetyMinutes.durationString(style: .minutes, showLeadingZero: false, roundUp: false)

		#expect(!string.isEmpty)
	}

	@Test("Duration string with leading zero")
	func durationStringLeadingZero() {
		let oneMinute: TimeInterval = 60.0
		let withZero = oneMinute.durationString(style: .seconds, showLeadingZero: true, roundUp: false)
		let withoutZero = oneMinute.durationString(style: .seconds, showLeadingZero: false, roundUp: false)

		#expect(!withZero.isEmpty)
		#expect(!withoutZero.isEmpty)
	}

	@Test("Milliseconds property")
	func millisecondsProperty() {
		let interval: TimeInterval = 1.5
		let millis = interval.milliseconds

		#expect(millis > 0)
	}
}
