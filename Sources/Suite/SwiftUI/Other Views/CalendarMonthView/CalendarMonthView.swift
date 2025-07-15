//
//  CalendarDatePicker.swift
//  Internal
//
//  Created by Ben Gottlieb on 12/16/24.
//

import SwiftUI


public struct CalendarMonthViewOptions: Equatable, Sendable {
	public enum WeekdayLabelFormat: Sendable { case letter, short, veryShort, none }
	
	public init(showMonthName: Bool = true, showYear: Bool = true, weekdayLabels: WeekdayLabelFormat = .short) {
		self.showMonthName = showMonthName
		self.showYear = showYear
		self.weekdayLabels = weekdayLabels
	}
	
	public var showMonthName = true
	public var showYear = true
	public var weekdayLabels = WeekdayLabelFormat.short
}

@available(iOS 16, macOS 14.0, watchOS 10, *)
public struct CalendarMonthView<DayView: View, WeekDayLabel: View>: View {
	@State var date: Date
	@Binding var selected: Date
	let overrideDate: Date?
	
	@State var showingMonthsAndYears = false
	let options: CalendarMonthViewOptions
	let dayBuilder: (Date.Day, MonthDayOptions) -> DayView
	let weekDayLabelBuilder: (Date.DayOfWeek) -> WeekDayLabel

	public init(date: Binding<Date>, display: Date? = nil, options: CalendarMonthViewOptions = .init(), @ViewBuilder dayBuilder: @escaping (Date.Day, MonthDayOptions) -> DayView, @ViewBuilder weekDayLabelBuilder: @escaping (Date.DayOfWeek) -> WeekDayLabel) {
		_selected = date
		_date = State(initialValue: display ??  date.wrappedValue)
		self.dayBuilder = dayBuilder
		self.weekDayLabelBuilder = weekDayLabelBuilder
		self.options = options
		self.overrideDate = display
	}
	
	public var body: some View {
		VStack {
			if options.showYear || options.showMonthName {
				monthYearBar(includeSpacer: false).opacity(0)
			}
			
			if showingMonthsAndYears {
				monthYearList
				#if os(macOS)
					WeeksView(date: date, selected: $selected, options: options, dayBuilder: dayBuilder, weekDayLabelBuilder: weekDayLabelBuilder)
				#endif
			} else {
				WeeksView(date: date, selected: $selected, options: options, dayBuilder: dayBuilder, weekDayLabelBuilder: weekDayLabelBuilder)
			}
		}
		.overlay(alignment: .top) {
			monthYearBar(includeSpacer: true)
		}
		.clipped()
		.onChange(of: overrideDate) { newDate in if let newDate { date = newDate } }
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
	
	@ViewBuilder func monthYearBar(includeSpacer: Bool) -> some View {
		if options.showYear || options.showMonthName {
			HStack {
				showYearMonthListButton
				if includeSpacer { Spacer() }
				if options.showMonthName {
					previousMonthButton
					nextMonthButton
				}
			}
		}
	}
}

@available(iOS 16, macOS 14.0, watchOS 10, *)
extension CalendarMonthView where DayView == CalendarSingleDayView, WeekDayLabel == CalendarWeekDayLabel {
	public init(date: Binding<Date>, display: Date? = nil, options: CalendarMonthViewOptions = .init()) {
		self.init(date: date, display: display, options: options, dayBuilder: { day, options in
			CalendarSingleDayView(day: day, options: options, rowSize: 24.0)
		}, weekDayLabelBuilder: { day in CalendarWeekDayLabel(day: day, options: options) })
	}
}

@available(iOS 16, macOS 14.0, watchOS 10, *)
extension CalendarMonthView where WeekDayLabel == CalendarWeekDayLabel {
	public init(date: Binding<Date>, display: Date? = nil, options: CalendarMonthViewOptions = .init(), @ViewBuilder dayBuilder: @escaping (Date.Day, MonthDayOptions) -> DayView) {
		self.init(date: date, display: display, options: options, dayBuilder: dayBuilder, weekDayLabelBuilder: { day in CalendarWeekDayLabel(day: day, options: options) })
	}
}

@available(iOS 16, macOS 14, *)
struct CalendarPreview: View {
	@State var date: Date = .now
	
	var body: some View {
		VStack {
			Text(date.formatted(date: .complete, time: .omitted))
			CalendarMonthView(date: $date)
				.border(.red)
			CalendarMonthView(date: $date, options: .init(showMonthName: false))
				.border(.red)
			CalendarMonthView(date: $date, options: .init(showYear: false))
				.border(.red)
			CalendarMonthView(date: $date, options: .init(showMonthName: false, showYear: false, weekdayLabels: .letter))
				.border(.red)
		}
		.font(.title)
		.padding()
	}
}

//#Preview  {
//	
//	if #available(iOS 16, macOS 14, *) {
//		CalendarPreview(date: .now)
//	} else {
//		// Fallback on earlier versions
//	}
//}

