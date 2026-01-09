//
//  NSAlert.swift
//  
//
//  Created by ben on 5/3/20.
//

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSAlert {
	public static func showAlert(title: String, message: String, buttonTitles: [String] = [NSLocalizedString("OK", comment: "OK")], style: NSAlert.Style = .informational, in window: NSWindow? = nil, completion: (@MainActor (Int) -> Void)? = nil) {
		
		MainActor.run {
			let alert = NSAlert()
			
			for title in buttonTitles {
				alert.addButton(withTitle: title)
			}
			
			alert.informativeText = message
			alert.messageText = title
			alert.alertStyle = style
			
			alert.show(in: window, completion: completion)
		}
	}
	
	public func show(in window: NSWindow?, completion: (@MainActor (Int) -> Void)? = nil) {
		let finish: @MainActor @Sendable (NSApplication.ModalResponse) -> Void = { response in
			switch response {
			case NSApplication.ModalResponse.alertFirstButtonReturn: completion?(0)
			case NSApplication.ModalResponse.alertSecondButtonReturn: completion?(1)
			case NSApplication.ModalResponse.alertThirdButtonReturn: completion?(2)
			default: completion?((response.rawValue - NSApplication.ModalResponse.alertThirdButtonReturn.rawValue) + 3)
			}
		}
		
		Task { @MainActor in
			if let window {
				self.beginSheetModal(for: window) { response in
					Task { @MainActor in finish(response) }
				}
			} else {
				let response = self.runModal()
				finish(response)
			}
		}
	}
}

#endif
