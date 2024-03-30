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

@attached(peer, names: prefixed(GeneratedPreferenceKey_))
@attached(accessor, names: named(get))
public macro GeneratedPreferenceKey() = #externalMacro(module: "SuiteMacrosImpl", type: "PreferenceKeyGenerator")

@attached(peer, names: prefixed(nonIsolatedActorAccessor_))
@attached(accessor, names: named(get), named(set))
public macro AddIsolatedAccessors(observing: Bool = false) = #externalMacro(module: "SuiteMacrosImpl", type: "NonIsolatedActorAccessorGenerator")


public struct PreferenceValues { }
