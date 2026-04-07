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

	public init(day: Date.Day, options: MonthDayOptions) {
		self.day = day
		self.options = options
	}

	public var body: some View {
		let text = (options.contains(.isPreviousMonth) || options.contains(.isNextMonth)) ? " " : "\(day.day)"
		ZStack {
			if options.contains(.isSelected) {
				Text(text)
					.foregroundColor(.white)
					.background {
						GeometryReader { geo in
							Circle()
								.fill(.red)
								.frame(width: geo.size.height + 3, height: geo.size.height + 3)
								.position(x: geo.size.width / 2, y: geo.size.height / 2)
						}
					}
					.zIndex(-1)
			} else {
				Text(text)
			}
		}
		.padding(.vertical, 4)
		.lineLimit(1)
		.minimumScaleFactor(0.5)
	}
}

