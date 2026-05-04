//
//  ErrorHandling.swift
//  
//
//  Created by ben on 9/17/19.
//

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
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

			let finish: @Sendable (NSApplication.ModalResponse) -> Void = { result in
				switch result {
				case .alertFirstButtonReturn: completion?(0)
				case .alertSecondButtonReturn: completion?(1)
				case .alertThirdButtonReturn: completion?(2)
				default: break
				}
			}

			if let win = window {
				alert.beginSheetModal(for: win, completionHandler: finish)
			} else {
				finish(alert.runModal())
			}
		}
	}

#endif
