//
//  File.swift
//  Suite
//
//  Created by Ben Gottlieb on 10/28/24.
//

import Foundation
import OSLog

fileprivate let delimiter = "/"

@available(iOS 15.0, macOS 14, watchOS 9, *)
extension Slog {
	actor File: Sendable, Hashable, Equatable, Identifiable {
		nonisolated let url: URL
		var lines: [Line] = []
		
		static func ==(lhs: File, rhs: File) -> Bool { lhs.url == rhs.url }
		nonisolated func hash(into hasher: inout Hasher) {
			hasher.combine(url)
		}
		nonisolated var id: URL { url }
		
		nonisolated var name: String {
			url.lastPathComponent
		}
		
		init(url: URL? = nil) {
			self.url = url ?? .currentURL()
//			print("Setting up logging to \(self.url.path)")
		}
		
		func record(_ message: String) {
			lines.append(.init(date: Date(), message: message))
			save()
		}
		
		static func allFiles() -> [File] {
			guard let urls = try? FileManager.default.contentsOfDirectory(at: .logsDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { return [] }
			
			return urls.map { File(url: $0) }
		}
		
		static func clearAllFiles() {
			try? FileManager.default.removeItem(at: .logsDirectory)
			try? FileManager.default.createDirectory(at: .logsDirectory, withIntermediateDirectories: true)
		}
		
		nonisolated func removeLog() {
			try? FileManager.default.removeItem(at: url)
		}
		
		@discardableResult func load(headerOnly: Bool = false) -> Header? {
			guard FileManager.default.fileExists(at: self.url), lines.isEmpty else { return nil }
			guard let data = try? Data(contentsOf: url) else { return nil }
			guard let string = String(data: data, encoding: .utf8) else { return nil }
			let lines = string.components(separatedBy: "\n")
			guard !lines.isEmpty else { return nil }
			
			guard let header = Header(rawValue: lines[0]) else { return nil }
			if headerOnly { return header }
			
			self.lines = lines.dropFirst().compactMap { .init(rawValue: $0) }
			return header
		}
		
		func save() {
			guard !lines.isEmpty else { return }
			let header = Header(start: lines.first!.date, end: lines.last!.date, count: lines.count)
			
			let lines = [header.rawValue] + lines.map { $0.rawValue }
			guard let data = lines.joined(separator: "\n").data(using: .utf8) else { return }
			
			do {
				try data.write(to: url)
			} catch {
				print("Failed to write slog: \(error) at \(url.path)")
			}
		}
	}
}

@available(iOS 15.0, macOS 14, watchOS 9, *)
extension Slog.File {
	struct Header: RawRepresentable, Sendable {
		let start: Date
		let end: Date
		let count: Int
		
		init?(rawValue: String) {
			let components = rawValue.components(separatedBy: .init(charactersIn: delimiter))
			if components.count != 3 { return nil }
			
			guard let start = DateFormatter.iso8601.date(from: components[0]) else { return nil }
			guard let end = DateFormatter.iso8601.date(from: components[1]) else { return nil }
			guard let count = Int(components[2]) else { return nil }
			self.init(start: start, end: end, count: count)
		}
		
		init (start: Date, end: Date, count: Int) {
			self.start = start
			self.end = end
			self.count = count
		}
		
		var rawValue: String {
			let formatter = DateFormatter.iso8601
			
			return ["\(formatter.string(from: start))", formatter.string(from: end), "\(count)"].joined(separator: delimiter)
		}
	}

	struct Line: RawRepresentable, Identifiable, Sendable {
		let id = UUID()
		let date: Date
		let message: String

		init?(rawValue: String) {
			let components = rawValue.components(separatedBy: .init(charactersIn: delimiter))
			if components.count < 2 { return nil }
			
			guard let date = DateFormatter.iso8601.date(from: components[0]) else { return nil }
			
			self.init(date: date, message: components.dropFirst().joined(separator: delimiter))
		}
		
		init (date: Date, message: String) {
			self.date = date
			self.message = message
		}
		
		var rawValue: String {
			DateFormatter.iso8601.string(from: date) + delimiter + message
		}
	}
}

fileprivate extension URL {
	nonisolated static var logsDirectory: URL {
		URL.documents.appendingPathComponent("slogs")
	}
	
	nonisolated static func currentURL() -> URL {
		let filename = DateFormatter.iso8601.string(from: Date()).replacingOccurrences(of: ":", with: "-")
		let logsDirectory = logsDirectory
		
		try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

		return logsDirectory.appendingPathComponent(filename + ".txt")
	}
}
