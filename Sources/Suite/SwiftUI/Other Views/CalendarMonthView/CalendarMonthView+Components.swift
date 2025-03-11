//
//  CalendarMonthView+Components.swift
//  Internal
//
//  Created by Ben Gottlieb on 1/14/25.
//

import SwiftUI

@available(iOS 16, macOS 14.0, watchOS 10, *)
extension CalendarMonthView {
	var nextMonthButton: some View {
		Button(action: {
			selected = date.byAdding(months: 1)
		}) {
			Image(systemName: "chevron.right")
				.foregroundStyle(.red)
		}
		.buttonStyle(.plain)
	}

	var previousMonthButton: some View {
		Button(action: {
			date = date.byAdding(months: -1)
		}) {
			Image(systemName: "chevron.left")
				.foregroundStyle(.red)
		}
		.buttonStyle(.plain)
	}

	@ViewBuilder var monthYearList: some View {
		#if os(iOS)
			MultiColumnPicker(labels: ["Month", "Year"], data: [
				monthNames,
				(Date.now.year - 50...Date.now.year).map { "\($0)" }
			], selection: monthYearBinding)
			.transition(.move(edge: .top))
		#endif
	}
	
	var showYearMonthListButton: some View {
		Button(action: { withAnimation { showingMonthsAndYears.toggle() }}) {
			showYearMonthListTitle
				.foregroundStyle(showingMonthsAndYears ? .red : .primary)
		}
		.buttonStyle(.plain)
		#if os(macOS)
		.popover(isPresented: $showingMonthsAndYears, attachmentAnchor: .point(.init(x: 0, y: 0)), arrowEdge: .leading) {
				MonthYearPopover(date: $date)
			}
		#endif
	}
	
	@ViewBuilder var showYearMonthListTitle: some View {
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
