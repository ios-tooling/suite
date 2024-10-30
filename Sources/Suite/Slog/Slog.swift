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
	
	let logger = Logger(subsystem: "suite", category: "general")
	
	init() {
		file = .init()
	}
	
	public func setPrintLogs(_ print: Bool) {
		printLogs = print
	}
	
	public func setEnabled(_ enabled: Bool) {
		disabled = !enabled
	}
	
	public func record(_ message: (any CustomStringConvertible)?) async {
		guard let message else { return }
		let raw: String = "\(message)"
		//logger.info("\(raw)")
		if printLogs { print(raw) }
		
		if !disabled { await file?.record(raw) }
	}
}

@available(iOS 15.0, macOS 14, watchOS 9, *)
public func slog(_ content: String) {
	Task {
		await Slog.instance.record(content)
	}
}
