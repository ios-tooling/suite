//
//  CalendarDatePicker.swift
//  Internal
//
//  Created by Ben Gottlieb on 12/16/24.
//

import SwiftUI


public struct CalendarMonthViewOptions: Equatable, Sendable {
	public init(showMonthName: Bool = true, showYear: Bool = true) {
		self.showMonthName = showMonthName
		self.showYear = showYear
	}
	
	public var showMonthName = true
	public var showYear = true
}

@available(iOS 16, macOS 14.0, watchOS 10, *)
public struct CalendarMonthView<DayView: View>: View {
	@State var date: Date
	@Binding var selected: Date
	
	@State var showingMonthsAndYears = false
	let options: CalendarMonthViewOptions
	let dayBuilder: (Date.Day, MonthDayOptions) -> DayView
	
	public init(date: Binding<Date>, display: Date? = nil, options: CalendarMonthViewOptions = .init(), @ViewBuilder builder: @escaping (Date.Day, MonthDayOptions) -> DayView) {
		_selected = date
		_date = State(initialValue: display ??  date.wrappedValue)
		dayBuilder = builder
		self.options = options
	}
	
	public var body: some View {
		VStack {
			if options.showYear || options.showMonthName {
				HStack {
					showYearMonthListButton
					Spacer()
					if options.showMonthName {
						previousMonthButton
						nextMonthButton
					}
				}
			}
			if showingMonthsAndYears {
				monthYearList
				#if os(macOS)
					WeeksView(date: date, selected: $selected, builder: dayBuilder)
				#endif
			} else {
				WeeksView(date: date, selected: $selected, builder: dayBuilder)
			}
		}
		.clipped()
	}
	
	var monthNames: [String] { Date.Month.allCases.map { $0.name }}
	var monthYearBinding: Binding<[String]> {
		.init(get: {
			[date.month.name, "\(date.year)"]
		}, set: { newValue in
			var components = Calendar.current.dateComponents([.month, .year, .day, .hour, .minute, .second], from: date)
			components.month = (monthNames.firstIndex(of: newValue[0]) ?? 0) + 1
			components.year = Int(newValue[1])
			
			date = Calendar.current.date(from: components) ?? date
		})
	}
}

@available(iOS 16, macOS 14.0, watchOS 10, *)
extension CalendarMonthView where DayView == CalendarSingleDayView {
	public init(date: Binding<Date>, display: Date? = nil, options: CalendarMonthViewOptions = .init()) {
		self.init(date: date, display: display, options: options) { day, options in
			CalendarSingleDayView(day: day, options: options, rowSize: 24.0)
		}
	}
}

//#Preview {
//	@Previewable @State var date: Date = .now
//	VStack {
//		Text(date.formatted(date: .complete, time: .omitted))
//		CalendarMonthView(date: $date)
//		CalendarMonthView(date: $date, options: .init(showMonthName: false))
//		CalendarMonthView(date: $date, options: .init(showYear: false))
//		CalendarMonthView(date: $date, options: .init(showMonthName: false, showYear: false))
//	}
//	.font(.title)
//	.padding()
//}

