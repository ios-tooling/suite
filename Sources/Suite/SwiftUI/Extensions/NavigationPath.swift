//
//  NavigationPath.swift
//  Suite
//
//  Created by Ben Gottlieb on 2/26/25.
//

import SwiftUI

@available(iOS 16.0, macOS 12, watchOS 9, *)
public extension NavigationPath {
	mutating func popToRoot() {
		while count > 0 { self.removeLast() }
	}
}
