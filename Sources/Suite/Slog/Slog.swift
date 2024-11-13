//
//  Slog.swift
//  Suite
//
//  Created by Ben Gottlieb on 10/28/24.
//

import Foundation
import OSLog

@available(iOS 15.0, macOS 14, watchOS 9, *)
public actor Slog {
	public static let instance = Slog()
	var file: File?
	var printLogs = Gestalt.isAttachedToDebugger
	var disabled = true
	var echoCallback: (@MainActor (String) -> Void)?
	var echoToConsole = false
	
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
	
	public func record(_ message: (any CustomStringConvertible)?) async {
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
		if !disabled { await file?.record(raw) }
	}
}

@available(iOS 15.0, macOS 14, watchOS 9, *)
public func slog(_ content: String) {
	Task {
		await Slog.instance.record(content)
	}
}
