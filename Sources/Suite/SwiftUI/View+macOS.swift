//
//  View+macOS.swift
//  
//
//  Created by Ben Gottlieb on 3/12/23.
//

#if canImport(AppKit)
#if os(macOS)

import AppKit

public enum UIKeyboardType { case alphabet }

@available(OSX 10.15, *)
public extension View {
	func closeCurrentWindow() {
		#if targetEnvironment(macCatalyst)
		
		#else
			NSApplication.shared.keyWindow?.close()
		#endif
	}
	
	func keyboardType(_ type: UIKeyboardType) -> some View {
		self
	}

}
#endif
#endif
