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
		@ViewBuilder var builder: (Date.Day, MonthDayOptions) -> DayView
				
		let rowSize = 24.0
		var body: some View {
			let cells = Array(repeating: GridItem(.fixed(rowSize), alignment: .center), count: 7)
			
			LazyVGrid(columns: cells, spacing: 0) {
				ForEach(dates, id: \.self) { dayDate in
					let day = Date.Day(day: dayDate, month: date.month, year: date.year)
					let options = options(for: dayDate)
					Button(action: { selected = day.date }) {
						builder(day, options)
							.contentShape(.rect)
					}
					.buttonStyle(.plain)
				}
			}
		}
		
		func options(for dateIndex: Int) -> MonthDayOptions {
			var results: MonthDayOptions = []
			
			if dateIndex < 0 { results.insert(.isPreviousMonth) }
			if dateIndex == selected.day.day { results.insert(.isSelected) }
			
			return results
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
