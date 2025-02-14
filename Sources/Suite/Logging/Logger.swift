//
//  Logger.swift
//  Suite
//
//  Created by Ben Gottlieb on 2/14/25.
//

import Foundation
import os.log

@available(iOS 14.0, macOS 12, watchOS 9, *)
let SuiteLogger = Logger(subsystem: .suiteLoggerSubsystem, category: "suite")

@available(iOS 14.0, macOS 12, watchOS 9, *)
public let AppLogger = Logger(subsystem: .appLoggerSubsystem, category: "application")



public extension String {
	static let suiteLoggerSubsystem = Bundle.main.bundleIdentifier! + ".suite"
	static let appLoggerSubsystem = Bundle.main.bundleIdentifier!
}
