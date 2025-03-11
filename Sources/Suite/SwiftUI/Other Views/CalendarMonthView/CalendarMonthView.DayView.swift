//
//  CalendarDatePicker.DayView.swift
//  Internal
//
//  Created by Ben Gottlieb on 1/4/25.
//

import SwiftUI

@available(iOS 16, macOS 14.0, watchOS 10, *)
public struct CalendarSingleDayView: View {
	let day: Date.Day
	let options: MonthDayOptions
	let rowSize: CGFloat
	
	public var body: some View {
		let text = (options.contains(.isPreviousMonth) || options.contains(.isNextMonth)) ? " " : "\(day.day)"
		ZStack {
			if options.contains(.isSelected) {
				Text(text)
					.foregroundColor(.white)
					.background {
						Circle()
							.fill(.red)
							.frame(width: rowSize + 3, height: rowSize + 3)
					}
					.zIndex(-1)
			} else {
				Text(text)
			}
		}
		.frame(height: rowSize)
		.lineLimit(1)
		.minimumScaleFactor(0.5)
	}
}

