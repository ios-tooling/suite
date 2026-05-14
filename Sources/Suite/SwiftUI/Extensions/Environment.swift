//
//  Environment.swift
//
//
//  Created by Ben Gottlieb on 3/19/23.
//

import SwiftUI

@available(iOS 14, macOS 11, watchOS 7, tvOS 16, *)
extension EnvironmentValues {
	@Entry public var namespace: Namespace.ID!
}

@available(iOS 16.0, macOS 13, watchOS 9, tvOS 16, *)
public extension EnvironmentValues {
	@Entry var navigationPath: Binding<NavigationPath> = .constant(NavigationPath())
}

public extension EnvironmentValues {
	@Entry var isEditing: Bool = false
	@Entry var isScrolling: Bool = false
	@Entry var dismissParent: () -> Void = { }
}
