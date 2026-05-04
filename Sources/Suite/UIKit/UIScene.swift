//
//  UIScene.swift
//  
//
//  Created by ben on 3/22/20.
//

#if canImport(UIKit) && !os(watchOS)

import UIKit

@available(iOS 13.0, tvOS 13.0, visionOS 1.0, *)
@MainActor public extension UIWindowScene {
	/// The key window in this scene, if any; falls back to the first window.
	var frontWindow: UIWindow? {
		if let window = self.windows.first(where: { $0.isKeyWindow }) { return window }
		return self.windows.first
	}

	/// The first regular-level window (`windowLevel == .normal`); falls back to the first window.
	/// Different from `frontWindow`, which returns the key window — useful when the key window is a
	/// transient overlay (alert/share/popover) and you want the underlying app content.
	var mainWindow: UIWindow? {
		if let window = self.windows.first(where: { $0.windowLevel == .normal }) { return window }
		return self.windows.first
	}
}

#endif

