//
//  SuiteMacros.swift
//
//
//  Created by Ben Gottlieb on 3/16/24.
//

import Foundation

@freestanding(declaration, names: arbitrary)
public macro GeneratedPreferenceKey<V>(name: String, type: V.Type, defaultValue: V? = nil) = #externalMacro(module: "SuiteMacrosImpl", type: "PreferenceKeyGenerator")

@attached(peer, names: prefixed(nonIsolatedBackingContainer_))
@attached(accessor, names: named(get), named(set))
public macro NonisolatedContainer(observing: Bool = false) = #externalMacro(module: "SuiteMacrosImpl", type: "NonisolatedContainerGenerator")
