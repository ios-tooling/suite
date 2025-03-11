//
//  CalendarDatePicker.WeeksView.swift
//  Internal
//
//  Created by Ben Gottlieb on 12/16/24.
//

import SwiftUI

@available(iOS 16, macOS 14.0, watchOS 10, *)
public struct MonthDayOptions: OptionSet, Sendable {
	public let rawValue: Int
	public init(rawValue: Int) { self.rawValue = rawValue }
	
	public static let isToday = MonthDayOptions(rawValue: 1 << 0)
	public static let isSelected = MonthDayOptions(rawValue: 1 << 1)
	public static let isPreviousMonth = MonthDayOptions(rawValue: 1 << 2)
	public static let isNextMonth = MonthDayOptions(rawValue: 1 << 3)
}

@available(iOS 16, macOS 14.0, watchOS 10, *)
extension CalendarMonthView {
	struct WeeksView: View {
		let date: Date
		@Binding var selected: Date
		let options: CalendarMonthViewOptions
		@ViewBuilder var dayBuilder: (Date.Day, MonthDayOptions) -> DayView
		@ViewBuilder var weekDayLabelBuilder: (Date.DayOfWeek) -> WeekDayLabel

		let rowSize = 24.0
		var body: some View {
			let weeks = weeks
			VStack {
				if options.weekdayLabels != .none {
					weekLabels(maximizeWidth: false).opacity(0)
				}

				Grid() {
					ForEach(weeks.indices, id: \.self) { weekIndex in
						let week = weeks[weekIndex]
						GridRow {
							ForEach(week.indices, id: \.self) { dayIndex in
								let dayDate = week[dayIndex]
								let day = Date.Day(day: dayDate, month: date.month, year: date.year)
								let options = options(for: dayDate)
								Button(action: { selected = day.date }) {
									dayBuilder(day, options)
										.contentShape(.rect)
								}
								.buttonStyle(.plain)
							}
						}
					}
				}
			}
			.overlay(alignment: .top) {
				if options.weekdayLabels != .none {
					weekLabels(maximizeWidth: true)
				}
			}
		}
		
		@ViewBuilder func weekLabels(maximizeWidth: Bool) -> some View {
			Grid() {
				GridRow {
					ForEach(Date.DayOfWeek.weekdays) { day in
						weekDayLabelBuilder(day)
							.frame(maxWidth: maximizeWidth ? .infinity : nil)
					}
				}
			}
		}
		
		@ViewBuilder var oldBody: some View {
			let cells = Array(repeating: GridItem(.fixed(rowSize), alignment: .center), count: 7)

			VStack(spacing: 0) {
				if options.weekdayLabels != .none {
					LazyVGrid(columns: cells, spacing: 0) {
						ForEach(Date.DayOfWeek.weekdays) { day in
							weekDayLabelBuilder(day)
						}
					}
				}
				
				LazyVGrid(columns: cells, spacing: 0) {
					ForEach(dates, id: \.self) { dayDate in
						let day = Date.Day(day: dayDate, month: date.month, year: date.year)
						let options = options(for: dayDate)
						Button(action: { selected = day.date }) {
							dayBuilder(day, options)
								.contentShape(.rect)
						}
						.buttonStyle(.plain)
					}
				}
			}
		}
		
		func options(for dateIndex: Int) -> MonthDayOptions {
			var results: MonthDayOptions = []
			
			if dateIndex < 0 { results.insert(.isPreviousMonth) }
			if dateIndex == selected.day.day { results.insert(.isSelected) }
			
			return results
		}
		
		var weeks: [[Int]] {
			dates.breakIntoChunks(ofSize: 7)
		}

		var dates: [Int] {
			var days = Array(1...date.numberOfDaysInMonth).map { $0 }
			for i in 1..<date.firstDayOfWeekInMonth.rawValue {
				days.insert(-i, at: 0)
			}
			return days
		}
	}
}
