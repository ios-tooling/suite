//
//  SlogScreen.swift
//  Suite
//
//  Created by Ben Gottlieb on 10/28/24.
//

import Foundation
import SwiftUI

@available(iOS 17.0, macOS 14, watchOS 9, *)
public struct SlogScreen: View {
	@State var files: [Slog.File] = []
	@State var current: Slog.File?
	@Environment(\.dismiss) var dismiss
	
	public var body: some View {
		VStack {
			Text("Logs").font(.title)
			Picker("File", selection: $current) {
				ForEach(files) { file in
					Text(file.name).tag(Optional.some(file))
				}
			}
			.pickerStyle(.menu)
			
			if let current {
				SlogView(file: current)
			}
			Spacer()
			
			HStack {
				if !files.isEmpty {
					Button("Clear All") {
						Slog.File.clearAllFiles()
						files = []
						current = nil
						dismiss()
					}
					
					if let current {
						Button("Clear Log") {
							current.removeLog()
							files.remove(current)
							self.current = nil
						}
					}
				}
			}
			.buttonStyle(.bordered)
		}
		.task {
			files = Slog.File.allFiles()
			current = await Slog.instance.file ?? files.first
		}
	}
}
