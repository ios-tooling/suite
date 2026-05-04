//
//  MonthYearPopover.swift
//  Internal
//
//  Created by Ben Gottlieb on 1/14/25.
//

import SwiftUI

@available(iOS 16, macOS 14.0, watchOS 10, tvOS 16, *)
struct MonthYearPopover: View {
	@Binding var date: Date
	@ScaledMetric private var listHeight: CGFloat = 150

	var body: some View {
		HStack {
			MonthList(date: $date)
			YearList(date: $date)
		}
		.frame(height: listHeight)
	}
}

@available(iOS 16, macOS 14.0, watchOS 10, tvOS 16, *)
private struct MonthList: View {
	@Binding var date: Date

	var body: some View {
		ScrollViewReader { scroller in
			ScrollView(showsIndicators: false) {
				VStack(alignment: .leading) {
					ForEach(Date.Month.allCases, id: \.self) { month in
						Button(action: { date = date.byChanging(month: month.rawValue) }) {
							HStack(spacing: 1) {
								Image(systemName: "checkmark")
									.opacity(month == date.month ? 1 : 0)
								Text(month.name)
							}
						}
						.buttonStyle(.plain)
						.id(month)
					}
				}
			}
			.onAppear { scroller.scrollTo(date.month, anchor: .center) }
		}
		.padding()
	}
}

@available(iOS 16, macOS 14.0, watchOS 10, tvOS 16, *)
private struct YearList: View {
	@Binding var date: Date

	var body: some View {
		ScrollViewReader { scroller in
			ScrollView(showsIndicators: false) {
				VStack {
					let years = (Date().year - 50...Date().year)
					ForEach(years, id: \.self) { year in
						Button(action: { date = date.byChanging(year: year) }) {
							HStack(spacing: 1) {
								Image(systemName: "checkmark")
									.opacity(year == date.year ? 1 : 0)
								Text(String(format: "%d", year))
							}
						}
						.buttonStyle(.plain)
						.id(year)
					}
				}
			}
			.onAppear { scroller.scrollTo(date.year, anchor: .center) }
		}
		.padding()
	}
}
