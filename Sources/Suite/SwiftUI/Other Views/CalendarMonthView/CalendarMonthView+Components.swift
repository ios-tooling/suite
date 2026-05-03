//
//  CalendarMonthView+Components.swift
//  Internal
//
//  Created by Ben Gottlieb on 1/14/25.
//

import SwiftUI

@available(iOS 16, macOS 14.0, watchOS 10, tvOS 16, *)
struct MonthStepButton: View {
	@Binding var date: Date
	let direction: Int
	let systemImage: String

	var body: some View {
		Button(action: { date = date.byAdding(months: direction) }) {
			Image(systemName: systemImage)
				.foregroundStyle(.red)
		}
		.buttonStyle(.plain)
	}
}

@available(iOS 16, macOS 14.0, watchOS 10, tvOS 16, *)
struct MonthYearList: View {
	@Binding var date: Date
	let monthYearBinding: Binding<[String]>
	let monthNames: [String]

	var body: some View {
		#if os(iOS)
			MultiColumnPicker(labels: ["Month", "Year"], data: [
				monthNames,
				(Date.now.year - 50...Date.now.year).map { "\($0)" }
			], selection: monthYearBinding)
			.transition(.move(edge: .top))
		#else
			EmptyView()
		#endif
	}
}

@available(iOS 16, macOS 14.0, watchOS 10, tvOS 16, *)
struct ShowYearMonthListButton: View {
	@Binding var date: Date
	@Binding var showingMonthsAndYears: Bool
	let options: CalendarMonthViewOptions

	var body: some View {
		Button(action: { withAnimation { showingMonthsAndYears.toggle() } }) {
			ShowYearMonthListTitle(date: date, showingMonthsAndYears: showingMonthsAndYears, options: options)
				.foregroundStyle(showingMonthsAndYears ? .red : .primary)
		}
		.buttonStyle(.plain)
		#if os(macOS)
		.popover(isPresented: $showingMonthsAndYears, attachmentAnchor: .point(.init(x: 0, y: 0)), arrowEdge: .leading) {
			MonthYearPopover(date: $date)
		}
		#endif
	}
}

@available(iOS 16, macOS 14.0, watchOS 10, tvOS 16, *)
struct ShowYearMonthListTitle: View {
	let date: Date
	let showingMonthsAndYears: Bool
	let options: CalendarMonthViewOptions

	var body: some View {
		HStack {
			if !options.showMonthName {
				Text(date.yearString)
			} else if !options.showYear {
				Text(date.month.name)
			} else {
				Text(date.month.name + " " + date.yearString)
			}

			Image(systemName: "chevron.right")
				.foregroundStyle(.red)
				.rotationEffect(.degrees(showingMonthsAndYears ? 90 : 0))
		}
		.bold()
	}
}
