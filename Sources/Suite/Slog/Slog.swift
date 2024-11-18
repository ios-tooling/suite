//
//  Slog.swift
//  Suite
//
//  Created by Ben Gottlieb on 10/28/24.
//

import Foundation
import OSLog
import SwiftUI

@available(iOS 15.0, macOS 14, watchOS 9, *)
public actor Slog {
	public static let instance = Slog()
	var file: File?
	var printLogs = Gestalt.isAttachedToDebugger
	var disabled = true
	var echoCallback: (@MainActor (String) -> Void)?
	var echoToConsole = false
	
	public enum LogColor: String, Codable, Sendable { case content = "#content", note = "#note", error = "#error"
		var color: Color {
			switch self {
			case .content: .primary
			case .note: .primary.opacity(0.4)
			case .error: .red
			}
		}
	}
	
	let logger = Logger(subsystem: "suite", category: "general")
	
	init() {
		file = .init()
	}
	
	public func setPrintLogs(_ print: Bool) {
		printLogs = print
	}
	
	public func setEchoToConsole(_ echo: Bool) {
		echoToConsole = echo
	}
	
	public func setEnabled(_ enabled: Bool) {
		disabled = !enabled
	}
	
	public func setEchoCallback(_ callback: @MainActor @escaping (String) -> Void) {
		echoCallback = callback
	}
	
	public func clearEchoCallback() {
		echoCallback = nil
	}
	
	public func record(_ message: (any CustomStringConvertible)?, color: LogColor? = nil) async {
		guard let message else { return }
		let raw: String = "\(message)"
		//logger.info("\(raw)")
		if printLogs { print(raw) }
		if let echoCallback {
			await echoCallback(raw)
		}
		if echoToConsole {
			await Console.instance.print(raw)
		}
		if !disabled { await file?.record(raw, color: color) }
	}
}

@available(iOS 15.0, macOS 14, watchOS 9, *)
public func slog(_ content: String, color: Slog.LogColor? = nil) {
	Task {
		await Slog.instance.record(content, color: color)
	}
}


