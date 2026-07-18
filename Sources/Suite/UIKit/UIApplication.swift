//
//  UIApplication.swift
//  
//
//  Created by ben on 12/14/19.
//

#if canImport(UIKit) && !os(watchOS)

import UIKit

@available(iOS 13.0, tvOS 13.0, visionOS 1.0, *)
@MainActor public extension UIApplication {
	var currentScene: UIWindowScene? {
		let scene = self.connectedScenes
			.filter { $0.activationState == .foregroundActive }
			.compactMap { $0 as? UIWindowScene }
			.first
		
		if let scene { return scene }
		
		return self.connectedScenes
			.filter { $0.activationState == .foregroundInactive }
			.compactMap { $0 as? UIWindowScene }
			.first
	}
}

@MainActor public extension UIApplication {
    var currentWindow: UIWindow? {
		 if let window = currentScene?.frontWindow { return window }

		if let window = self.delegate?.window { return window }
		 #if os(visionOS)
			return nil
		 #else
			return connectedScenes
				.compactMap { $0 as? UIWindowScene }
				.flatMap(\.windows)
				.first
		 #endif
    }

}

#endif

