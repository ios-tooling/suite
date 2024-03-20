//
//  NonIsolatedActorAccessorGenerator.swift
//
//
//  Created by Ben Gottlieb on 3/16/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct NonIsolatedActorAccessorGenerator: PeerMacro {
	public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
		
		// Skip non-variables
		guard let varDecl = declaration.as(VariableDeclSyntax.self) else { 
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.notVariableSyntax))
			return []
		}
		
		guard var patternBinding = varDecl.bindings.first?.as(PatternBindingSyntax.self) else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.missingAnnotation))
			return []
		}
		
		guard let identifier = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.notAnIdentifier))
			return []
		}
		
		let originalPattern = patternBinding.typeAnnotation?.type.root
		patternBinding.pattern = PatternSyntax(IdentifierPatternSyntax(identifier: .identifier("defaultValue")))
		//guard let typeAnnotation = patternBinding.typeAnnotation else { return [] }
		guard let initializer = patternBinding.initializer else { return [] }
		let isOptional = patternBinding.typeAnnotation?.type.is(OptionalTypeSyntax.self) ?? false
		let hasDefaultValue = patternBinding.initializer != nil
		let trimmedInitializer = initializer.value
		
		guard isOptional || hasDefaultValue else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.noDefaultArgument))
			return []
		}

		return [
				"""
					/* \(raw: varDecl.bindings) */
					/* \(raw: originalPattern) */
					private let nonIsolatedActorAccessor_\(raw: identifier) = CurrentValueSubject(value: \(trimmedInitializer))
				"""
		]
	 }
}

extension NonIsolatedActorAccessorGenerator: AccessorMacro {
	public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
		
		// Skip non-variables
		guard let varDecl = declaration.as(VariableDeclSyntax.self) else { return [] }
		
		guard let patternBinding = varDecl.bindings.first?.as(PatternBindingSyntax.self) else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.missingAnnotation))
			return []
		}
		
		guard let identifier = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.notAnIdentifier))
			return []
		}
		
		return [
				"""
				get { nonIsolatedActorAccessor_\(raw: identifier).value }
				""",
				"""
				set { nonIsolatedActorAccessor_\(raw: identifier).value = newValue }
				"""
		]
	}
}
