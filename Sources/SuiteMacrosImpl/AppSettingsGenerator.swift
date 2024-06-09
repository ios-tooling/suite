//
//  AppSettingsGenerator.swift
//
//
//  Created by Ben Gottlieb on 6/8/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct AppSettingsGenerator: MemberMacro {
	public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
		
		let members = declaration.memberBlock.members
			.compactMap { $0.decl.as(VariableDeclSyntax.self) }
			.map { $0.patternBinding }
		
		return [
			"""
			var sample = 1
			"""
		]
	}
}
