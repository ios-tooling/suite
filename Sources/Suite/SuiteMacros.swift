//
//  SuiteMacros.swift
//
//
//  Created by Ben Gottlieb on 3/16/24.
//

import Foundation

@attached(peer, names: prefixed(GeneratedEnvironmentKey_))
@attached(accessor, names: named(get), named(set))
public macro GeneratedEnvironmentKey() = #externalMacro(module: "SuiteMacrosImpl", type: "EnvironmentKeyGenerator")

@freestanding(declaration, names: arbitrary)
public macro GeneratedPreferenceKey<V>(name: String, type: V.Type, defaultValue: V? = nil) = #externalMacro(module: "SuiteMacrosImpl", type: "PreferenceKeyGenerator")

@attached(peer, names: prefixed(nonIsolatedBackingContainer_))
@attached(accessor, names: named(get), named(set))
public macro NonisolatedContainer(observing: Bool = false) = #externalMacro(module: "SuiteMacrosImpl", type: "NonisolatedContainerGenerator")

public protocol ObservableUserDefaultsContainer: UserDefaultsContainer & ObservableObject { }
//@attached(member, names: arbitrary)
@attached(extension, names: arbitrary, conformances: ObservableUserDefaultsContainer)
public macro AppSettings(_ group: String? = nil) = #externalMacro(module: "SuiteMacrosImpl", type: "AppSettingsGenerator")

@attached(accessor)
public macro AppSettingsProperty() = #externalMacro(module: "SuiteMacrosImpl", type: "AppSettingsPropertyMacro")
