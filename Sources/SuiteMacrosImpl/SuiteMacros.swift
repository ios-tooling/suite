//
//  SuiteMacros.swift
//
//
//  Created by Ben Gottlieb on 3/16/24.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SuiteMacros: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		EnvironmentKeyGenerator.self,
		NonisolatedContainerGenerator.self,
		PreferenceKeyGenerator.self,
		AppSettingsGenerator.self,
		AppSettingsPropertyMacro.self
	]
}
