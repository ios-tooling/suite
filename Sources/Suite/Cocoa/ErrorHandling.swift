//
//  ErrorHandling.swift
//  
//
//  Created by ben on 9/17/19.
//

import Foundation

#if !canImport(UIKit)
	import Cocoa
	import AppKit

	@MainActor extension Error {
		public func display(in window: NSWindow? = nil, title: String? = nil, message: String? = nil, buttons: [String]? = nil, completion: (@Sendable (Int) -> Void)? = nil) {
			let alert = NSAlert(error: self)
			
			if let title = title {
				alert.messageText = title
				alert.informativeText = message ?? self.localizedDescription
			}
			
			if let buttons = buttons {
				buttons.forEach { button in
					alert.addButton(withTitle: button)
				}
			} else {
				alert.addButton(withTitle: NSLocalizedString("OK", comment: "OK"))
			}
			
			if let win = window {
				alert.beginSheetModal(for: win) { result in
					if result == NSApplication.ModalResponse.alertFirstButtonReturn { completion?(0) }
					if result == NSApplication.ModalResponse.alertSecondButtonReturn { completion?(1) }
					if result == NSApplication.ModalResponse.alertThirdButtonReturn { completion?(2) }
				}
			} else {
				let result = alert.runModal()
				if result == NSApplication.ModalResponse.alertFirstButtonReturn { completion?(0) }
				if result == NSApplication.ModalResponse.alertSecondButtonReturn { completion?(1) }
				if result == NSApplication.ModalResponse.alertThirdButtonReturn { completion?(2) }
			}
		}
	}

#endif
