//
//  SlogView.swift
//  Suite
//
//  Created by Ben Gottlieb on 10/28/24.
//

import SwiftUI

@available(iOS 17.0, macOS 14, watchOS 9, *)
struct SlogView: View {
	let file: Slog.File
	@State var lines: [Slog.File.Line] = []
	
	var body: some View {
		List {
			ForEach(lines) { line in
				VStack(alignment: .leading) {
					Text(line.message)
						.multilineTextAlignment(.leading)
						.font(.system(size: 12).monospaced())
					
					Text(line.date.formatted(date: .omitted, time: .complete))
						.font(.caption.monospaced())
				}
			}
		}
		.listStyle(.plain)
		.onChange(of: file, initial: true) {
			Task {
				await file.load()
				lines = await file.lines
			}
		}
	}
}
