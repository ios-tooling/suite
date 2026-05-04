//
//  NSView.swift
//  
//
//  Created by ben on 5/3/20.
//

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor public extension NSView {
	/// `set` enables layer-backing if necessary. `get` returns nil if the view isn't layer-backed yet.
	var backgroundColor: NSColor? {
		set { self.wantsLayer = true; self.layer?.backgroundColor = newValue?.cgColor }
		get { if let color = self.layer?.backgroundColor { return NSColor(cgColor: color) }; return nil }
	}

	var isInDarkMode: Bool {
		let appearance = self.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
		return appearance == .darkAqua
	}
}

#endif
