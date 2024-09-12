//
//  Gestalt+Background.swift
//  
//
//  Created by Ben Gottlieb on 5/20/24.
//

import Foundation

#if os(iOS)
import UIKit
import OSLog

@available(iOS 14.0, *)
fileprivate let logger = Logger(subsystem: "suite", category: "codableFileStorage")

@MainActor fileprivate var application: UIApplication?

public extension Gestalt {
	@MainActor static func setApplication(_ app: UIApplication) {
		application = app
	}
	
	@MainActor static func startSafeBackgroundProcess(name: String? = nil, handler: (() -> Void)? = nil) -> Any? {
		guard let application else {
			if !Gestalt.isExtension {
				if #available(iOS 14.0, *) {
					logger.error("Please call Gestalt.setApplication() first")
				}
			}
			return nil
		}
		
		let result = application.beginBackgroundTask(withName: name) {
			handler?()
		}
		
		return result
	}
	
	@MainActor static func endSafeBackgroundProcess(using token: Any?) {
		guard let token = token as? UIBackgroundTaskIdentifier else { return }
		application?.endBackgroundTask(token)
	}
}

#else
public extension Gestalt {
	static func setApplication(_ any: Any?) {
	}
	
	static func startSafeBackgroundProcess(name: String? = nil, handler: (() -> Void)? = nil) -> Any? {
		return nil
	}
	
	static func endSafeBackgroundProcess(using token: Any?) {
	}
}
#endif
