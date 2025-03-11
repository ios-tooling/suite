//
//  MonthYearPopover.swift
//  Internal
//
//  Created by Ben Gottlieb on 1/14/25.
//

import SwiftUI

@available(iOS 16, macOS 14.0, watchOS 10, *)
struct MonthYearPopover: View {
	@Binding var date: Date
	
	var body: some View {
		HStack {
			monthList
			yearList
		}
		.frame(height: 150)
	}
	
	func selectMonth(_ month: Date.Month) {
		date = date.byChanging(month: month.rawValue)
	}
	
	func selectYear(_ year: Int) {
		date = date.byChanging(year: year)
	}
	
	var monthList: some View {
		ScrollViewReader { scroller in
			ScrollView(showsIndicators: false) {
				VStack(alignment: .leading) {
					ForEach(Date.Month.allCases, id: \.self) { month in
						Button(action: { selectMonth(month) }) {
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
			.onAppear { scroller.scrollTo(date.month, anchor: .center)}
		}
		.padding()
	}
	
	var yearList: some View {
		ScrollViewReader { scroller in
			ScrollView(showsIndicators: false) {
				VStack {
					let years = (Date().year - 50...Date().year)
					ForEach(years, id: \.self) { year in
						Button(action: { selectYear(year) }) {
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

//#Preview {
//	MonthYearPopover(date: .constant(.now))
//}
