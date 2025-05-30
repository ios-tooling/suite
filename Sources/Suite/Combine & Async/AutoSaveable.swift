//
//  AutoSaveable.swift
//  
//
//  Created by Ben Gottlieb on 2/17/22.
//

import Foundation
import OSLog

@available(iOS 14.0, macOS 11.0, watchOS 7, *)
fileprivate let logger = Logger(subsystem: "suite", category: "autosaveable")

@available(iOS 14.0, macOS 11.0, watchOS 7, *)
public protocol AutoSaveable: Codable, ObservableObject {
	static var saveURL: URL { get }
	init()
}

@available(iOS 14.0, macOS 11.0, watchOS 7, *)
extension AutoSaveable {
	@MainActor public static func loadSaved() -> Self {
		do {
			if let data = try? Data(contentsOf: saveURL) {
				let decoded = try JSONDecoder().decode(Self.self, from: data)
				return decoded.setupForAutoSave()
			}
		} catch {
			logg("Failed to decode \(String(describing: self)): \(error)")
		}
		return Self.init().setupForAutoSave()
	}
	
	@MainActor func setupForAutoSave() -> Self {
		self
			.objectWillChange
			.sink { [weak self] _ in
				self?.autoSave()
			}
			.sequester(String(describing: self))
		
		return self
	}
	
	public func autoSave() {
		do {
			let data = try JSONEncoder.default.encode(self)
			try data.write(to: Self.saveURL)
		} catch {
			logger.error("Failed to save \(String(describing: self)): \(error)")
		}
	}
}
