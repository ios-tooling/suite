//
//  CalendarWeekDayLabel.swift
//  Suite
//
//  Created by Ben Gottlieb on 1/15/25.
//

import SwiftUI

public struct CalendarWeekDayLabel: View {
	let day: Date.DayOfWeek
	let options: CalendarMonthViewOptions
	
	public var body: some View {
		Group {
			switch options.weekdayLabels {
			case .none: EmptyView()
			case .short: Text(day.shortName)
			case .veryShort: Text(day.veryShortName)
			case .letter: Text(day.abbreviation)
			}
		}
		.font(.caption)
		.lineLimit(1)
		.minimumScaleFactor(0.5)
	}
}
