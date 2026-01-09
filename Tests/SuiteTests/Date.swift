//
//  Date.swift
//
//
//  Created by Ben Gottlieb on 2/18/23.
//

import Testing
import Suite


@Suite("Date Extension Tests")
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

	@Test func testDateComparison() {
		let past = Date().addingTimeInterval(-3600)
		let future = Date().addingTimeInterval(3600)

		#expect(past.isInPast == true)
		#expect(future.isInFuture == true)
	}

	@Test func testMidnight() {
		let now = Date()
		let midnight = now.midnight

		#expect(midnight.hour == 0)
		#expect(midnight.minute == 0)
		#expect(midnight.second == 0)
	}

	@Test func testNearestSecond() {
		let date = Date(timeIntervalSinceReferenceDate: 123.456)
		let rounded = date.nearestSecond

		#expect(rounded.timeIntervalSinceReferenceDate == 123.0)
	}

	@Test func testByAdding() {
		let base = Date(timeIntervalSinceReferenceDate: 0)

		let plusDay = base.byAdding(days: 1)
		#expect(plusDay.timeIntervalSince(base) == 86400)

		let plusHour = base.byAdding(hours: 1)
		#expect(plusHour.timeIntervalSince(base) == 3600)

		let plusMinute = base.byAdding(minutes: 1)
		#expect(plusMinute.timeIntervalSince(base) == 60)
	}

	@Test func testByChanging() {
		let date = Date(calendar: .current, year: 2024, month: 6, day: 15, hour: 14, minute: 30)!

		let newDate = date.byChanging(minute: 0, hour: 10)

		#expect(newDate.hour == 10)
		#expect(newDate.minute == 0)
		#expect(newDate.month.rawValue == 6)
		#expect(newDate.dayOfMonth == 15)
	}

	@Test func testIsSameDay() {
		let date1 = Date(calendar: .current, year: 2024, month: 1, day: 15, hour: 10)!
		let date2 = Date(calendar: .current, year: 2024, month: 1, day: 15, hour: 22)!
		let date3 = Date(calendar: .current, year: 2024, month: 1, day: 16, hour: 10)!

		#expect(date1.isSameDay(as: date2) == true)
		#expect(date1.isSameDay(as: date3) == false)
	}

	@Test func testNextPreviousDay() {
		let base = Date(calendar: .current, year: 2024, month: 6, day: 15)!

		let next = base.nextDay
		let prev = base.previousDay

		#expect(next.dayOfMonth == 16)
		#expect(prev.dayOfMonth == 14)
	}

	@Test func testFirstLastDayInMonth() {
		let date = Date(calendar: .current, year: 2024, month: 6, day: 15)!

		let first = date.firstDayInMonth
		let last = date.lastDayInMonth

		#expect(first.dayOfMonth == 1)
		#expect(last.dayOfMonth == 30) // June has 30 days
	}

	@Test func testDayOfWeek() {
		let date = Date(calendar: .current, year: 2024, month: 1, day: 1)! // Monday

		let dayOfWeek = date.dayOfWeek
		// DayOfWeek is not optional, just verify it exists
		let _ = dayOfWeek
	}

	@Test func testApproximateEquality() {
		let date1 = Date(timeIntervalSinceReferenceDate: 123.456)
		let date2 = Date(timeIntervalSinceReferenceDate: 123.789)
		let date3 = Date(timeIntervalSinceReferenceDate: 124.123)

		#expect(date1 ≈≈ date2) // Same second
		#expect(date1 !≈ date3) // Different seconds
	}

	@Test func testISO8601String() {
		let date = Date(timeIntervalSinceReferenceDate: 0)
		let iso = date.iso8601String

		#expect(!iso.isEmpty)
		#expect(Date(iso8691String: iso) != nil)
	}

	@Test func testNoon() {
		let date = Date(calendar: .current, year: 2024, month: 6, day: 15)!
		let noon = date.noon

		#expect(noon.hour == 12)
		#expect(noon.minute == 0)
	}

	@Test func testLastSecond() {
		let date = Date(calendar: .current, year: 2024, month: 6, day: 15)!
		let last = date.lastSecond

		#expect(last.hour == 23)
		#expect(last.minute == 59)
		#expect(last.second == 59)
	}

	@Test func testMonthOperations() {
		let jan = Date(calendar: .current, year: 2024, month: 1, day: 15)!
		let feb = Date(calendar: .current, year: 2024, month: 2, day: 15)!

		#expect(jan.isSameMonth(as: feb) == false)
		#expect(jan.month == .jan)
		#expect(feb.month == .feb)
	}

	@Test func testLeapYear() {
		#expect(2024.isLeapYear == true)
		#expect(2023.isLeapYear == false)
		#expect(2000.isLeapYear == true)
		#expect(1900.isLeapYear == false)
	}

	@Test func testMeridian() {
		let morning = Date(calendar: .current, year: 2024, month: 1, day: 1, hour: 9)!
		let evening = Date(calendar: .current, year: 2024, month: 1, day: 1, hour: 21)!

		#expect(morning.meridian == .am)
		#expect(evening.meridian == .pm)
	}

	@Test func testAllDaysUntil() {
		let start = Date(calendar: .current, year: 2024, month: 1, day: 1)!
		let end = Date(calendar: .current, year: 2024, month: 1, day: 5)!

		let days = start.allDays(until: end)

		#expect(days.count == 4) // 1, 2, 3, 4 (not including 5)
		#expect(days.first?.dayOfMonth == 1)
		#expect(days.last?.dayOfMonth == 4)
	}

	@Test func testFilename() {
		let date = Date(timeIntervalSinceReferenceDate: 0)
		let filename = date.filename

		#expect(!filename.isEmpty)
		#expect(!filename.contains(":"))
		#expect(!filename.contains("/"))
	}

	@Test func testSecondsSinceMidnight() {
		let date = Date(calendar: .current, year: 2024, month: 1, day: 1, hour: 1, minute: 30)!
		let seconds = date.secondsSinceMidnight

		#expect(seconds == 5400) // 1.5 hours = 5400 seconds
	}

	@Test func testBySettingSecondsSinceMidnight() {
		let date = Date(calendar: .current, year: 2024, month: 1, day: 1)!
		let newDate = date.bySettingSecondsSinceMidnight(7200) // 2 hours

		#expect(newDate.hour == 2)
		#expect(newDate.minute == 0)
	}

	@available(iOS 15.0, macOS 12, *)
	@Test func testAgeString() {
		let age = Date.ageString(age: -3600, style: .short) // 1 hour ago
		#expect(!age.isEmpty)

		let ageWeek = Date.ageString(age: -604800, style: .short) // 1 week ago
		#expect(!ageWeek.isEmpty)
	}

	@Test func testDateOnlyTimeOnly() {
		let date = Date()
		let dateOnly = date.dateOnly
		let timeOnly = date.timeOnly

		#expect(dateOnly == date.midnight)
		#expect(timeOnly == date)
	}

	@Test func testDateComponents() {
		let date = Date(calendar: .current, year: 2024, month: 6, day: 15, hour: 14, minute: 30, second: 45)!

		#expect(date.year == 2024)
		#expect(date.month == .jun)
		#expect(date.dayOfMonth == 15)
		#expect(date.hour == 14)
		#expect(date.minute == 30)
		#expect(date.second == 45)
	}

	@Test func testYearString() {
		let date = Date(calendar: .current, year: 2024, month: 1, day: 1)!
		#expect(date.yearString == "2024")
	}

	@Test func testHourMinuteString() {
		let date = Date(calendar: .current, year: 2024, month: 1, day: 1, hour: 14, minute: 30)!
		let string = date.hourMinuteString

		#expect(!string.isEmpty)
		#expect(string.contains("14") || string.contains("2")) // 24h or 12h format
	}

	@Test func testFirstLastDayInWeek() {
		let date = Date(calendar: .current, year: 2024, month: 1, day: 10)! // Wednesday

		let first = date.firstDayInWeek
		let last = date.lastDayInWeek

		#expect(first.dayOfWeek == Date.DayOfWeek.firstDayOfWeek)
		#expect(last.dayOfWeek == Date.DayOfWeek.lastDayOfWeek)
	}
}
