//
//  UITraitCollection.swift
//  
//
//  Created by ben on 4/16/20.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

public extension UITraitCollection {
	var isInDarkMode: Bool { userInterfaceStyle == .dark }
}

#endif
