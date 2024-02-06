//
//  WebConsoleView.swift
//
//
//  Created by Ben Gottlieb on 2/6/24.
//

import SwiftUI

@available(macOS 12.0, iOS 15, watchOS 10, *)
public struct WebConsoleView: View {
	@ObservedObject var console: WebConsole
	@State private var reportedURL: URL?
	@State private var script = ""
	@State private var result = ""
	@State private var error: Error?
	
	public init(console: WebConsole) {
		self.console = console
	}
	
	public var body: some View {
		VStack {
			ScrollView {
				VStack {
					switch console.state {
					case .failed(let request, let error):
						Text(request?.url?.absoluteString ?? "--")
						Text(error.localizedDescription)
						
					case .loaded(let request):
						Text("loaded").font(.caption)
						Text(request?.url?.absoluteString ?? "--")
						
					case .loading(let request):
						Text("Loaded").font(.caption)
						Text(request?.url?.absoluteString ?? console.loadedURL?.absoluteString ?? "")
						
					case .idle:
						Text("No content")
						
					case .starting(let url):
						Text("Starting")
						Text(url?.absoluteString ?? "--")
					}

					Text("Reported: \(console.loadedURL?.absoluteString ?? "")")
					Button(action: { reportedURL = console.loadedURL }) {
						Text("Current: \(reportedURL?.absoluteString ?? "--")")
					}
					
					TextEditor(text: $script)
						.font(.system(size: 16, weight: .regular, design: .monospaced))
						.frame(minHeight: 50)
						
					AsyncButton("Run") { @MainActor in
						do {
							result = try await console.run(script: script)
						} catch {
							self.error = error
						}
					}
					.buttonStyle(.bordered)
					if let error {
						Text(error.localizedDescription)
					}
					Text(result)
				}
				.padding()
			}
		}
	}
}
